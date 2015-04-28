require 'test_helper'
require 'json'
require 'indexer'

describe Indexer do
  it "converts *.dat files from the CLEF 14 collection to JSON documents" do
    fixture = File.new("test/fixtures/clef14.dat")

    parsed_fixtures = [
      {
        :id => "attra0843_12_000001",
        :title => "ATTRACT | What is the evidence.."
      },
      {
        :id => "attra0843_12_000002",
        :title => "ATTRACT | Are there any other investigations"
      }
    ]

    i = 0
    Indexer.parse(fixture) do |document|
      document = JSON.parse(document)
      document["id"].must_equal parsed_fixtures[i][:id]
      document["title"].must_equal parsed_fixtures[i][:title]
      i += 1 
    end
  end 
end
