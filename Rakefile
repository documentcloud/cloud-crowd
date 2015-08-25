require 'rake/testtask'
require 'yaml'

# To get started testing, run `crowd -c test/config load_schema`, in order to
# create and load a fresh test database, and then `rake test`.
desc 'Run all tests'
task :test => ['test:drop_db', 'test:create_db'] do
  require 'minitest/autorun'
  $LOAD_PATH.unshift(File.expand_path('test'))
  Dir['./test/**/test_*.rb'].each {|test| require test }
end

namespace :gem do
  
  desc 'Build and install cloud-crowd gem'
  task :install do
    sh "gem build cloud-crowd.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --local --no-ri --no-rdoc"
  end
  
  desc 'Uninstall the cloud-crowd gem'
  task :uninstall do
    sh "sudo gem uninstall -x cloud-crowd"
  end
  
end

namespace :test do

  desc 'Wipe out local databases'
  task :drop_db do
    path = YAML.load(File.read('./test/config/database.yml'))[:database]
    FileUtils.rm path if File.exists? path
  end

  desc "Create local database"
  task :create_db do
    load_db_code
    # Load in schema
    require 'cloud_crowd/schema.rb'
  end
end

def load_db_code
  # Load Code
  require File.expand_path(File.dirname(__FILE__)) + "/lib/cloud-crowd"
  config_directory = File.expand_path(File.dirname(__FILE__)) + "/test/config"
  CloudCrowd.configure("#{config_directory}/config.yml")
  # Connect to DB
  require 'cloud_crowd/models'
  CloudCrowd.configure_database("#{config_directory}/database.yml", false)
end

task :default => :test
