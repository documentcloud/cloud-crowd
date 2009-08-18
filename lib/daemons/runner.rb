RAILS_ENV = ENV['RAILS_ENV'] || 'development' unless defined?(RAILS_ENV)
RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../..') unless defined?(RAILS_ROOT)

# Standard Lib and Gems
require 'rubygems'
require 'daemons'
require 'socket'
require 'yaml'
require 'json'
require 'rest_client'
require 'right_aws'

# Daemon/Worker Dependencies.
require "#{RAILS_ROOT}/lib/dogpile"
Dir["#{RAILS_ROOT}/lib/dogpile/*.rb"].each {|ruby| require ruby }
Dir["#{RAILS_ROOT}/actions/*.rb"].each {|ruby| require ruby }

# TODO: Kick off the number of workers specified in dogpile.yml.
Daemons.run("#{RAILS_ROOT}/lib/daemons/daemon.rb", {
  :app_name   => "dogpile_worker",
  :multiple   => true,
  :backtrace  => true,
  :log_output => true
})
