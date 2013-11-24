ENV['RACK_ENV'] = 'test'
require 'rubygems'

require 'pry'
require 'faker'
require 'sham'
require 'rack/test'
require 'shoulda'
require 'shoulda/context'
require 'shoulda/matchers/active_record'
require 'machinist/active_record'
require 'mocha/setup'

here = File.dirname(__FILE__)
require File.expand_path(here + "/../lib/cloud-crowd")
CloudCrowd.configure(here + '/config/config.yml')
CloudCrowd.configure_database(here + '/config/database.yml')

require "#{CloudCrowd::ROOT}/test/blueprints.rb"

class Test::Unit::TestCase
  include CloudCrowd
  include Shoulda::Matchers::ActiveRecord
  extend Shoulda::Matchers::ActiveRecord
  include Shoulda::Matchers::ActiveModel
  extend Shoulda::Matchers::ActiveModel
end
