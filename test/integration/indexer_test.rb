require 'test_helper'
require 'indexer'
require 'rsolr'

describe Indexer do
  before do
    @fixture = File.new("test/fixtures/clef14.dat")
    @parsed_fixtures = [
      {
        :id => "attra0843_12_000001",
        :title => "ATTRACT | What is the evidence.."
      },
      {
        :id => "attra0843_12_000002",
        :title => "ATTRACT | Are there any other investigations"
      }
    ]
  end

  describe "process" do
    it "sends batches of parsed documents to a solr client" do
      solr_client = RSolr.connect "http://127.0.0.1:9999/solr/pphs_test"
      solr_client.delete_by_query "*:*"
      solr_client.commit
      solr_client.get('select', :params => {:q => '*:*', :wt => :json})[:response][:docs].must_be_empty
      indexer = Indexer.new(solr_client)
      indexer.batch_size = 2
      indexer.process(@fixture)

      result = solr_client.get('select', :params => {:q => '*:*', :wt => :json})[:response][:docs]
      @parsed_fixtures.each do |f|
        result.collect { |h| h[:id] }.must_include f[:id]
        result.collect { |h| h[:title][0] }.must_include f[:title]
      end
    end
  end
end
