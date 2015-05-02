require_relative 'db_conn'
require 'open-uri'
require 'nokogiri'
require 'csv'


class Icd9Chapter < ActiveRecord::Base
  def self.inc_u(u, chapter)
    if @incs == nil
      headers = CSV.foreach("incidence_male.csv").first
      @incs = {}

      @incs[:male] = {}
      @incs[:male][:sum] = {}
      CSV.foreach("incidence_male.csv") do |row|
        @incs[:male][row[0]] = {}
        row[1..(row.size - 1)].each_with_index do
          |v, index| 
          @incs[:male][row[0]][headers[index + 1]] = BigDecimal.new(v) 
          @incs[:male][:sum][headers[index + 1]] ||= BigDecimal.new("0") 
          @incs[:male][:sum][headers[index + 1]] += BigDecimal.new(v) 
        end
      end

      @incs[:female] = {}
      @incs[:female][:sum] = {}
      CSV.foreach("incidence_female.csv") do |row|
        @incs[:female][row[0]] = {}
        row[1..(row.size - 1)].each_with_index do
          |v, index| 
          @incs[:female][row[0]][headers[index + 1]] = BigDecimal.new(v) 
          @incs[:female][:sum][headers[index + 1]] ||= BigDecimal.new("0") 
          @incs[:female][:sum][headers[index + 1]] += BigDecimal.new(v) 
        end
      end

      @incs[:asex] = {}
      @incs[:asex][:sum] = {}
      CSV.foreach("incidence.csv") do |row|
        @incs[:asex][row[0]] = {}
        row[1..(row.size - 1)].each_with_index do
          |v, index| 
          @incs[:asex][row[0]][headers[index + 1]] = BigDecimal.new(v) 
          @incs[:asex][:sum][headers[index + 1]] ||= BigDecimal.new("0") 
          @incs[:asex][:sum][headers[index + 1]] += BigDecimal.new(v) 
        end
      end
    end

    r = @incs[u.sex][chapter.code][u.age.to_s]
    if r.nil?
      r = BigDecimal.new("0")
    end
    r  / @incs[u.sex][:sum][u.age.to_s]
  end


  def self.update_json(command)
    command = JSON.generate(command)

    s = TCPSocket.new 'localhost', 8983
    s.puts "POST /solr/wiki_cond/update HTTP/1.1"
    s.puts "User-Agent: curl/7.30.0"
    s.puts "Host: localhost:8983"
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

  def self.wiki_list
    if @wiki_list.nil?
      wiki_list_doc = Nokogiri::HTML(open("http://en.wikipedia.org/wiki/List_of_ICD-9_codes")).xpath("//a").select { |a| a.text =~ /List of ICD/ }
      @wiki_list = []
      wiki_list_doc.each do |w|
        next unless /(\d\d\d).(\d\d\d)/ =~ w
        @wiki_list << {
          :xml => Nokogiri::HTML(open("http://en.wikipedia.org#{w.attributes['href'].text}")),
          :from => /(\d\d\d).(\d\d\d)/.match(w.text)[1],
          :to => /(\d\d\d).(\d\d\d)/.match(w.text)[2]
        }
      end      
    end 
    @wiki_list
  end


  has_many :discharges

  def self.without_V_and_E
    where("substring(code from 1 for 1) <> E'V' AND substring(code from 1 for 1) <> E'E'")
  end

  def self.with_mesh
    where("mesh != E'none' OR mesh IS NULL")
  end

  def self.load_mesh_from_api
    inp, outp = nil

    begin
      Dir.chdir("utsapi2_0") do
        inp, outp, stderr, waithr = Open3.popen3("java MeshExtractor")
      end
      Icd9Chapter.where(:mesh => nil).uniq.each do |c|
        c.load_mesh_from_api(inp, outp)
        puts "loaded for #{c.mesh} mesh for #{c.code}"
      end
    ensure
      inp.close
      outp.close
    end
  end

  def self.load_title_from_uts
    inp, outp = nil

    begin
      Dir.chdir("utsapi2_0") do
        inp, outp, stderr, waithr = Open3.popen3("java ICD10Extractor")
      end
      Icd9Chapter.without_V_and_E.where(:title => nil).each do |c|
        c.load_title_from_uts(inp, outp)
        puts "loaded for #{c.title} title for #{c.code}"
      end
    ensure
      inp.close
      outp.close
    end
  end

  def load_mesh_from_api(inpipe, outpipe)
    inpipe.puts(code)
    loop do 
      line = outpipe.gets
      break if line =~ /^\+\+\+\+\+/ || line.nil?
      line.strip!
      if line != ""
        self.mesh = line
        self.save!
      end
    end
    if self.mesh.nil? || self.mesh.empty?
      self.mesh = "none"
      self.save!
    end 
  end

  def load_wiki_content
    begin
      content = ""
      c = self::class.wiki_list.select { |l| l[:from].to_i <= code.to_i && l[:to].to_i >= code.to_i }
      return "" if c.empty?
      c = c.first
      c = c[:xml].xpath("//a[starts-with(text(),'#{code}')]")
      return "" if c.empty?
      c.each do |cc| 
        cc.parent.xpath("a").reject { |a| (/new/ =~ a['class'] || /external/ =~ a['class']) }.each do |l|
          content << File.read(open("http://en.wikipedia.org#{l['href']}"))
        end
      end
      unless content.empty?
        self.wiki = content
        self.save!
        puts "saved content for #{code}"
      end
    rescue StandardError => e
      $stderr.puts "there was an error for #{code}"
      $stderr.puts e.message
    end
  end

  def load_wiki_title
    begin
      content = ""
      c = self::class.wiki_list.select { |l| l[:from].to_i <= code.to_i && l[:to].to_i >= code.to_i }
      return  if c.empty?
      c = c.first
      c = c[:xml].xpath("//a[starts-with(text(),'#{code}')]")
      return  if c.empty?
      self.title = c.first.parent.text.gsub(/\n/,' ') 
      unless self.title.nil? || self.title.empty?
        self.save!
      end
    rescue StandardError => e
      $stderr.puts "there was an error for #{code}"
      $stderr.puts e.message
    end
  end

  def load_title_from_uts(inp, outp)
    Dir.chdir("utsapi2_0") do
      inp, outp, stderr, waithr = Open3.popen3("java ICD10Extractor")
      inp.puts(code)
      loop do 
        line = outp.gets
        puts line
        break if line =~ /^\+\+\+\+\+/ || line.nil?
        line.strip!
        if line != ""
          self.title = line.split(/\s/).uniq.join(" ")
          puts self.title
          self.save!
        end
      end
    end
  end

  def index
    command = { "add" => { "doc" => { "id" => code, "content" => wiki, "title" => title }}} 
    self.class.update_json(command)
    self.class.update_json({ "commit" => {} })
    save!
  end

  def self.search(query, limit = nil)
    uri = URI.parse("http://localhost:8983/solr/wiki_cond/select/")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({"defType" => "dismax", "q" => query, "qf" => "content", "wt" => "json", "rows" => limit || LIMIT, "fl" => "score,id,path,title"})
    response = http.request(request)

    return JSON.parse(response.body)
  end

  attr_accessor :pr_q_score, :weight, :female, :male

  def self.cached_doc(title)
    @cache_doc ||= {}
    if @cache_doc[title].nil?

       @cache_doc[title]= search(title, 1000)
    end
    @cache_doc[title]
  end

  def pr_t_cond_d(d)
    doc = self::class.cached_doc(d['title'])["response"]["docs"].find { |x| x["id"] == code }   
    unless doc.nil?
      result = BigDecimal.new(doc["score"].to_s) 
    else
      result =   BigDecimal.new("0")
    end
    result
  end

  def pr_q(q)
    pr_q_score
  end

  def inc(u)
    return 1
    return @cache[u] unless @cache.nil? || @cache[u].nil? 
   # age_a = [0, (u.age - 5)].max
   # age_b = [99, (u.age + 5)].min




    inc = self.weight / self.class.all_discharges_weight

    @cache ||= {}
    #inc = self.class.inc_u(u, self)
    @cache[u] = inc
    inc
  end

  def self.all_discharges_weight
    @all_discharges_weight ||= BigDecimal.new(Discharge.from_07.sum(:weight).to_s)
  end
end
