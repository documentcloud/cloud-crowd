ENV['RACK_ENV'] = 'test'
require 'rubygems'

require 'pry'
require 'faker'
require 'sham'
require 'rack/test'
require 'shoulda'
require 'shoulda/context'
require 'shoulda/matchers/active_record'
require 'shoulda/matchers/active_model'
require 'machinist/active_record'
require 'mocha/setup'
require 'byebug'

here = File.dirname(__FILE__)
require File.expand_path(here + "/../lib/cloud-crowd")
CloudCrowd.configure(here + '/config/config.yml')
CloudCrowd.configure_database(here + '/config/database.yml')

require "#{CloudCrowd::ROOT}/test/blueprints.rb"


module TestHelpers
  def setup
    CloudCrowd::WorkUnit.stubs(:distribute_to_nodes).returns([])
    CloudCrowd.stubs(:log)
    super
  end
  def teardown
      Mocha::Mockery.instance.teardown
      Mocha::Mockery.reset_instance
      super
  end
end

class Minitest::Test
  include TestHelpers
  include Shoulda::Matchers::ActiveRecord
  extend Shoulda::Matchers::ActiveRecord
  include Shoulda::Matchers::ActiveModel
  extend Shoulda::Matchers::ActiveModel
  include CloudCrowd
end
