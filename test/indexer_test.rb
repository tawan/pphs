require 'test_helper'
require 'json'
require 'indexer'

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


  it "converts content of *.dat files from the CLEF 14 collection to document objects" do


    i = 0
    Indexer.parse(@fixture) do |document|
      document[:id].must_equal @parsed_fixtures[i][:id]
      document[:title].must_equal @parsed_fixtures[i][:title]
      i += 1 
    end
  end 


  it "has a solr client" do
    Indexer.new({}).wont_be_nil
  end


  describe "process" do
    it "sends batches of parsed documents to a solr client" do
      solr_client = Minitest::Mock.new
      indexer = Indexer.new(solr_client)
      indexer.batch_size = 2
      document = {}

      solr_client.expect :add, nil, [ [ document, document ] ]
      solr_client.expect :commit, nil

      Indexer.stub :add_title, document do
        indexer.process(@fixture)
        solr_client.verify
      end
    end
  end
end
