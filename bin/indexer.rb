require 'rsolr'
require_relative '../lib/indexer'

require 'logger'

logger = Logger.new($stdout)
logger.level = Logger::INFO

if ARGV[0].nil?
  STDERR.puts "No url to solr core given"
  exit 2
end

solr_client = RSolr.connect :url => ARGV[0] #"http://127.0.0.1:8983/solr/pphs_clef"
logger.info "connected to ARGV[0]"
solr_client.delete_by_query "*:*"
solr_client.commit
logger.info "deleted all documents from index"


indexer = Indexer.new(solr_client, logger)
indexer.process($stdin)
