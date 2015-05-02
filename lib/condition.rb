require 'digest'
require 'json'
require 'socket'
require "net/http"
require "bigdecimal"
require "open3"
require_relative 'db_conn'
require_relative 'term'
require_relative 'icd9_chapter'

class Condition < ActiveRecord::Base
  has_many :discharges
  has_many :terms

  attr_accessor :pr_q_score, :weight

  module CLEF14
    END_OF_CONTENT = /^#EOR/
    UID = /^#UID:(\S+)/
    PATH = /^#PATH:(\S+)/
    DATE = /^#DATE/
    URL = /^#URL/
    CONTENT = /^#CONTENT/
    CORE = "clef14"

    MAX_INDEX_BASE = 100

    def contents(docs)
      doc_ids = docs.collect { |d| d[:id] }.uniq.compact
      paths = docs.collect { |d| d[:path] }.uniq.compact
      content = ""
      paths.each do |path|
        i = 0
        File.open(path, "r") do |infile|
          while (line = infile.gets)
            if i > 0 && line =~ END_OF_CONTENT
              i = 0
            end

            content << line if i == 2

            if i == 1 && line =~ CONTENT
              i = 2
            end

            if i == 0 && line =~ UID
              if  doc_ids.include?(line.match(UID)[1])
                i = 1
                doc_ids.delete(line.match(UID)[1])
              end
            end
          end
        end
      end
      return content
    end
  end

  module Trec
    CORE = "trec"
    def contents(docs)
      paths = docs.collect { |d| d[:path] }.uniq.compact
      content = ""
      paths.each do |p|
        content << File.read(p)
      end

      content
    end
  end

  LT_C = BigDecimal.new("0.92");

  attr_reader :qt

  def self.load_terms_from_api
    inp, outp = nil

    begin
      Dir.chdir("utsapi2_0") do
        inp, outp, stderr, waithr = Open3.popen3("java Main")
      end
      Condition.joins("LEFT OUTER JOIN terms on terms.condition_id = conditions.id").where("terms.id IS NULL").uniq.each do |c|
        c.load_terms_from_api(inp, outp)
        puts "loaded for #{c.terms.count} terms for #{c.icd_9_normalized}"
      end
    ensure
      inp.close
      outp.close
    end

  end


  def self.base=(base)
    @@base = base
    @@conditions_base = ProbabilisticModel::Base.new("conditions_#{self::CORE}", @@base.solr_port)
  end

  def self.index_all
    command = { "delete" => {"query" => "*:*"}} 
    update_json(command)
    update_json({ "commit" => {} })
    Condition.update_all(:indexed => false)
    Condition.update_all(:doc_id => nil)
    Condition.joins(:terms).uniq.each do |c|
      c.index
    end
  end

  def self.notV
    where("substring(conditions.icd_9 from 1 for 1) <> 'V'")
  end

  def self.without_V_and_E
    where("substring(icd_9 from 1 for 1) <> E'V' AND substring(icd_9 from 1 for 1) <> E'E'")
  end

  def self.indexed
    where(:indexed => true)
  end

  def load_terms_from_api(inpipe, outpipe)
    inpipe.puts(icd_9_normalized)
    loop do 
      line = outpipe.gets
      break if line =~ /^\+\+\+\+\+/ || line.nil?
      line.strip!
      terms.find_or_create_by(:name => line)
    end 
  end


  def icd_9_normalized
    return icd_9 if icd_9.size < 4
    icd_9[0..2] + "." + icd_9[3..(icd_9.length - 1)]
  end

  def generate_doc_id
    Digest::MD5.base64digest(qt) 
  end

  def pr_t_cond_d(d)
    @psi ||= @@base.solr.search(qt, 5000)
    @psi_maxScore ||= BigDecimal.new(@psi["response"]["maxScore"].to_s)
    doc = @psi["response"]["docs"].find { |x| x["id"] == d }
    return BigDecimal.new(doc["score"].to_s) unless doc.nil?
    BigDecimal.new("0")
  end

  def pr_q(q)
    pr_q_score || @@conditions_base.psi(doc_id, q)
  end

  def inc(u)

    return @cache[u] unless @cache.nil? || @cache[u].nil? 
  
    age_a = [0, (u.age - 5)].max
    age_b = [Discharge.from_07.in_years.maximum(:age), (u.age + 5)].min
    
    scope = discharges.from_07.send(u.sex).age_between(age_a, age_b)

    inc = BigDecimal.new(scope.sum(:weight).to_s) / BigDecimal.new(Discharge.from_07.send(u.sex).age_between(age_a,age_b).sum(:weight).to_s)

    @cache ||= {}
    @cache[u] = inc
    inc
  end

  def self.update_json(command)
    command = JSON.generate(command)

    s = TCPSocket.new 'localhost', @@conditions_base.solr_port
    s.puts "POST /solr/#{@@conditions_base.solr_core}/update HTTP/1.1"
    s.puts "User-Agent: curl/7.30.0"
    s.puts "Host: localhost:#{@@conditions_base.solr_port}"
    s.puts "Accept: */*"
    s.puts "Content-Type: application/json; charset=UTF-8"
    s.puts "Content-Length: #{command.bytesize}"
    s.puts "Expect: 100-continue"
    s.puts "\n"
    unless s.gets =~ /Continue/
      puts s.gets
      raise "POST REJECTED"
    end

    s.puts command

    s.gets
    unless s.gets =~ /OK/
      raise "BODY REJECTED"
    end
    s.close
  end

  def delete_from_index
    command = { "delete" => { "id" => doc_id }} 
    self.class.update_json(command)
    self.class.update_json({ "commit" => {} })
  end

  def index
    docs = lt_docs
    if docs.empty?
      self.indexed = false
      save!
      return
    end
    self.doc_id = generate_doc_id
    command = { "add" => { "doc" => { "id" => doc_id, "content" => contents(docs), "title" => "" }}} 
    self.class.update_json(command)
    self.class.update_json({ "commit" => {} })
    self.indexed = true
    save!
  end

  def qt
    terms.collect(&:name).collect { |t| "\"#{t.gsub(/"/,'')}\"" }.uniq.join(" OR ").gsub(/[\[\]:]/, '')
  end

  def lt_docs
    result = @@base.solr.search(qt)
    if result.nil? || result["response"].nil?
      puts qt
      puts result
      exit 1
    end 
    maxScore = BigDecimal.new(result["response"]["maxScore"].to_s)

    docs = result["response"]["docs"].collect { |d| { :id => d["id"], :path => d["path"], :score => d["score"] } }

    docs = docs.select do |d|
      score = BigDecimal.new(d[:score].to_s)
      score / maxScore > LT_C
    end

    puts "#{docs.count} docs found for #{qt}"

    return docs
  end
end
