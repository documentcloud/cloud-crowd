$0 = "houdini_daemon"
RAILS_ENV = ENV['RAILS_ENV'] || 'development' unless defined?(RAILS_ENV)
RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../..') unless defined?(RAILS_ROOT)

# Standard Lib and Gems
require 'rubygems'
require 'daemons'
require 'yaml'
require 'json'
require 'rest_client'
require 'benchmark'

# Daemon/Worker Dependencies.
require "#{RAILS_ROOT}/lib/houdini"
Dir["#{RAILS_ROOT}/lib/houdini/*.rb"].each {|ruby| require ruby }
Dir["#{RAILS_ROOT}/actions/*.rb"].each {|ruby| require ruby }

DEFAULT_SLEEP_TIME  = 1
MAX_SLEEP_TIME      = 20
SLEEP_MULTIPLIER    = 1.3

@sleep_time = DEFAULT_SLEEP_TIME
@worker = Houdini::Worker.new

# Daemons.daemonize

loop do
  $0 = 'houdini'
  puts 'going'
  @worker.fetch_work_unit
  if @worker.has_work?
    puts "running #{@worker.action} worker"
    time = Benchmark.measure { @worker.run }
    puts "ran in #{time}\n"
    @sleep_time = DEFAULT_SLEEP_TIME
  else
    @sleep_time = [@sleep_time * SLEEP_MULTIPLIER, MAX_SLEEP_TIME].min
    sleep @sleep_time
  end
end