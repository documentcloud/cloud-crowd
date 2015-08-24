require 'rake/testtask'

# To get started testing, run `crowd -c test/config load_schema`, in order to
# create and load a fresh test database, and then `rake test`.
desc 'Run all tests'
task :test do
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

namespace :db do

  desc 'Wipe out local databases'
  task :drop do
    sh "dropdb cloud_crowd && echo DROPPED DB"
  end

  desc "Create local database"
  task :create do
    sh "createdb cloud_crowd && echo CREATED DB"
    load_db_code
    # Load in schema
    require 'cloud_crowd/schema.rb'
  end

  desc 'Removes all items from blacklist'
  task :clearblacklist do
    load_db_code
    count = CloudCrowd::BlackListedAction.all.count
    CloudCrowd::BlackListedAction.destroy_all
    sh "echo REMOVED #{count} ITEMS FROM BLACKLIST"
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
