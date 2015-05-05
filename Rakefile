require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << [ 'test']
  t.warning = true
  t.pattern = "test/*_test.rb"
end

namespace :test do
  desc "Run integration tests"
  task :integration do
    Rake::TestTask.new("_integration") do |t|
      t.libs << [ 'test' ]
      t.warning = true
      t.test_files = FileList['test/integration/*_test.rb']
    end

    start_solr
    begin
      Rake::Task["_integration"].invoke
    ensure
      stop_solr
    end
  end

  desc "Run all tests"
  task :all do
    Rake::TestTask.new("_all") do |t|
      t.libs << [ 'test' ]
      t.warning = true
      t.test_files = FileList['test/**/*_test.rb']
    end

    start_solr
    begin
      Rake::Task["_all"].invoke
    ensure
      stop_solr
    end
  end

  def port
    9999
  end

  def start_solr
    if ENV['SOLR_BIN'].nil? || ENV['SOLR_BIN'].empty?
      raise "Please set SOLR_BIN to path of bin/ directory of your Solr installation."
    else
      Dir.chdir(ENV['SOLR_BIN']) do
        raise "Could not start solr server on port #{port}" unless system("./solr start -p #{port}")
      end
    end

  end

  def stop_solr
    Dir.chdir(ENV['SOLR_BIN']) do
      raise "Could not stop solr server on port #{port}" unless system("./solr stop -p #{port}")
    end
  end
end
