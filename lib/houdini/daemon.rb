require 'rubygems'
require 'daemons'
require 'curb'
require 'yaml'

RAILS_ENV = ENV['RAILS_ENV'] || 'development' unless defined?(RAILS_ENV)
RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../..') unless defined?(RAILS_ROOT)

MAX_SLEEP_TIME = 20
SLEEP_MULTIPLIER = 1.3

@sleep_time = 2.0
@worker = Houdini::Worker.new

Daemons.daemonize

loop do
  @worker.fetch_work_unit
  if @worker.has_work?
    @worker.run
  else
    @sleep_time = [@sleep_time * SLEEP_MULTIPLIER, MAX_SLEEP_TIME].min
  end
  sleep @sleep_time
end