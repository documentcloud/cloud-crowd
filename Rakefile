require 'rake/testtask'

desc 'Run all tests'
task :test do
  $LOAD_PATH.unshift(File.expand_path('test'))
  require 'redgreen' if Gem.available?('redgreen')
  require 'test/unit'  
  Dir['test/**/test_*.rb'].each {|test| require test }
end

namespace :gem do
  
  desc 'Build and install cloud-crowd gem'
  task :install do
    sh "gem build cloud-crowd.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --no-ri --no-rdoc"
  end
  
  desc 'Uninstall the cloud-crowd gem'
  task :uninstall do
    sh "sudo gem uninstall -x cloud-crowd"
  end
  
end

namespace :db do
  
  desc "Creates a MySQL 'cloud_crowd_test' database, and loads the schema"
  task :create_test_database do
    sh "mysqladmin -uroot create cloud_crowd_test"
    sh "bin/crowd -c test/config load_schema"
  end
  
end

task :default => :test
