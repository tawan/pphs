require 'nokogiri'

class Indexer
  END_OF_CONTENT = /^#EOR/
  UID = /^#UID:(\S+)/
  CONTENT = /^#CONTENT/

  def self.parse(raw)
    document = { :content => ''}
    content_flag = false
    raw.each_line do |line|
      if line =~ END_OF_CONTENT
        html = Nokogiri::HTML(document[:content])
        t = html.css("title")
        document[:title] = t.nil? ? "" : t.text
        
        yield JSON.generate(document)
        document = { :content => '' }
        content_flag = false
      end
      uid_match = line.match(UID)
      document[:id] = uid_match[1] unless uid_match.nil?
      document[:content] << line if content_flag
      content_flag = true if line =~ CONTENT
    end
  end
end
