# This is the script that kicks off a single CloudCrowd::Daemon. Because the 
# daemons don't load the entire rails stack, this file functions like a mini
# environment.rb, loading all the common gems that we need.

# CloudCrowd::App.environment = ENV['CloudCrowd::App.environment'] || 'development' unless defined?(CloudCrowd::App.environment)
# CloudCrowd::App.root = File.expand_path(File.dirname(__FILE__) + '/../..') unless defined?(CloudCrowd::App.root)

# Standard Lib and Gems
require 'rubygems'
require 'daemons'
require 'socket'
require 'yaml'
require 'json'
require 'rest_client'
require 'right_aws'

# Daemon/Worker Dependencies.
require "#{CloudCrowd::App.root}/lib/cloud_crowd"
Dir["#{CloudCrowd::App.root}/lib/cloud_crowd/*.rb"].each {|ruby| require ruby }

Daemons.run("#{CloudCrowd::App.root}/lib/daemons/daemon.rb", {
  :app_name   => "cloud_crowd_worker",
  :multiple   => true,
  :backtrace  => true,
  :log_output => true
})
