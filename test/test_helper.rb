ENV['RACK_ENV'] = 'test'
require 'rubygems'

here = File.dirname(__FILE__)
require File.expand_path(here + "/../lib/cloud-crowd")
CloudCrowd.configure(here + '/config/config.yml')
CloudCrowd.configure_database(here + '/config/database.yml')

require 'faker'
require 'sham'
require 'rack/test'
require 'shoulda/active_record'
require 'machinist/active_record'
require 'mocha'
require "#{CloudCrowd::ROOT}/test/blueprints.rb"

class Test::Unit::TestCase
  include CloudCrowd
end
