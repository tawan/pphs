require 'logger'
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
        yield add_title(document)
        document = { :content => '' }
        content_flag = false
      end
      uid_match = line.match(UID)
      document[:id] = uid_match[1] unless uid_match.nil?
      document[:content] << line if content_flag
      content_flag = true if line =~ CONTENT
    end
  end

  def self.add_title(document)
    html = Nokogiri::HTML(document[:content])
    t = html.css("title")
    document[:title] = t.nil? ? "" : t.text
    document
  end

  attr_reader :solr_client
  attr_writer :batch_size

  def initialize(solr_client, logger = nil)
    @logger = logger || Logger.new(File.open('/dev/null', 'w'))
    @solr_client = solr_client
  end

  def process(input)
    batch = []
    self.class.parse(input) do |document|
      batch << document
      if batch.size >= batch_size
        @solr_client.add batch
        @solr_client.commit
        @logger.info "Added batch of #{batch.size} documents"
        batch = []
      end
    end

    unless batch.empty?
      @solr_client.add batch
      @logger.info "Added batch of #{batch.size} documents"
      @solr_client.commit
    end
  end

  def batch_size
    @batch_size || 1000
  end
end
