require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << [ 'test', 'bin' ]
  t.warning = true
  t.pattern = "test/*_test.rb"
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.name = "test:integration"
  t.warning = true
  t.test_files = FileList['test/integration/*_test.rb']
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.warning = true
  t.name = "test:all"
  t.test_files = FileList['test/**/*_test.rb']
end
