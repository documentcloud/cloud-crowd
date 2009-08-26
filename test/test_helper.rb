require 'rubygems'

here = File.dirname(__FILE__)
require File.expand_path(here + "/../lib/cloud-crowd")
CloudCrowd.configure(here + '/config/test_config.yml')
CloudCrowd.configure_database(here + '/config/test_database.yml')

require 'faker'
require 'sham'
require 'rack/test'
require 'shoulda/active_record'
require 'machinist/active_record'
require "#{CloudCrowd::App.root}/test/blueprints.rb"

class Test::Unit::TestCase
  include CloudCrowd
end

# Dir['test/unit/*.rb'].each {|f| require f }
