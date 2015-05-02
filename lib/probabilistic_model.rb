require "uri" 
require "json"
require "net/http"
require "uri" 
require "bigdecimal"

require_relative "condition"

module ProbabilisticModel

  class Solr
    LIMIT = 1000

    def initialize(port, core)
      @port = port
      @core = core
    end

    def search(query, limit = nil)
      uri = URI.parse("http://localhost:#{@port}/solr/#{@core}/select/")

      http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data({"defType" => "dismax", "q" => query, "qf" => "content", "wt" => "json", "rows" => limit || LIMIT, "fl" => "score,id,title"})
      response = http.request(request)

      return JSON.parse(response.body)
    end

  end

  class U
    attr_accessor :age, :sex, :discharges_sum_weight

    def initialize(age, sex)
      self.age = age
      self.sex = sex
    end


    def pr_T_cond_q(t_u, q, base)

      @cache_q_sum ||= {}
      @cache_q_sum[q] ||= base.conditions.inject(BigDecimal.new("0")) do |sum, t|
        sum + (pr_T(t) * t.pr_q(q))
      end 

      return 1 if @cache_q_sum[q] == 0

      (pr_T(t_u) * t_u.pr_q(q)) / @cache_q_sum[q] 
    end

    def pr_T(t)
      t.inc(self)
    end
  end

  class Base
    RERANK = 150

    attr_reader :solr_core, :solr_port, :solr, :conditions

    def initialize(solr_core, solr_port, lam = nil)
      @lam = BigDecimal.new(lam) unless lam.nil?
      @solr = Solr.new(solr_port, solr_core)
      @conditions_solr = Solr.new(solr_port, "conditions_#{Condition::CORE}")
      @solr_core = solr_core
      @solr_port = solr_port
      @psi_cache = {}
    end

    def psi(d, q)
      unless @psi_cache[d].nil?
        return @psi_cache[d][q] unless @psi_cache[d][q].nil?
      else
        @psi_cache[d] = {}
      end

       
      @psi_cache[d][q] = @solr.score(q, d)
      @psi_cache[d][q]
    end

    def search(q, u)
      @conditions  = find_relevant_conditions(q,u)
      result = @solr.search(q)
      docs = result["response"]["docs"]
      maxScore = BigDecimal.new(result["response"]["maxScore"].to_s)
      rerank = self.class::RERANK
      if docs.count > rerank
        top_k = docs[0..(rerank -1)]
        remaining = docs[rerank..docs.size]
      else
        top_k = docs
        remaining = []
      end 

      top_k.each_with_index do |d, index|
        d["old_score"] = d["score"]
        d["old_rank"] = index + 1
        d["new_score"] = score(d, q, u, BigDecimal.new(d["score"].to_s))
      end
      top_k = top_k.sort { |a,b| b["new_score"] <=> a["new_score"] }
      top_k.each { |d| d["score"] = d["new_score"].to_f }

      return top_k  + remaining
    end

    def score(d, q, u, curr_psi = nil)
      max = -1
      (curr_psi || psi(d, q)) + @lam * (curr_psi || psi(d, q)) * @conditions.inject(BigDecimal.new("0")) do |sum, t| 
        tmp  = (t.pr_t_cond_d(d) * alpha(t, u, q)) 
        if tmp > max 
          d['max_cond'] = { :cond => t, :score => tmp }
          max = tmp
        end
        sum + tmp
      end
    end

    def alpha(t_d, u, q)
      u.pr_T_cond_q(t_d, q, self)
    end

    def find_relevant_conditions(q, u)
      @conditions_cache ||= {}
      return @conditions_cache[q] unless @conditions_cache[q].nil?

      sex = nil
      if (u.sex == :male)
        sex = 1
      else
        sex = 2
      end
      age_a = [0, (u.age - 5)].max
      age_b = [99, (u.age + 5)].min
      rel_conditions = Icd9Chapter.without_V_and_E.where("wiki IS NOT NULL").joins("JOIN discharges d ON d.icd9_chapter_id = icd9_chapters.id AND d.year = 7").distinct.group("icd9_chapters.id, code").sum("d.weight").collect { |code, weight| i = Icd9Chapter.new(:code => code); i.weight = weight; i }


      r = Icd9Chapter.search(q, 1000)
      docs = r["response"]["docs"]

      rel_conditions.each do |c|
        rel_doc = docs.find { |d| d["id"] == c.code }
        unless rel_doc.nil?
          c.pr_q_score = BigDecimal.new(rel_doc["score"].to_s) 
        else
          c.pr_q_score = BigDecimal.new("0")
        end
      end

      @conditions_cache[q] = rel_conditions.select { |c| c.pr_q_score > 0 }
      @conditions_cache[q]
    end
  end
end
