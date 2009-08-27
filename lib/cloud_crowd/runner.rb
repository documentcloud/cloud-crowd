# This is the script that kicks off a single CloudCrowd::Daemon. Because the 
# daemons don't load the entire rails stack, this file functions like a mini
# environment.rb, loading all the common gems that we need.

# Standard Libs
require 'fileutils'
require 'benchmark'
require 'socket'

# Gems
require 'rubygems'
require 'daemons'
require 'yaml'

FileUtils.mkdir('log') unless File.exists?('log')

# Daemon/Worker Dependencies.
require "#{File.dirname(__FILE__)}/../cloud-crowd"
require 'cloud_crowd/asset_store'

Daemons.run("#{CloudCrowd::ROOT}/lib/cloud_crowd/daemon.rb", {
  :app_name   => "cloud_crowd_worker",
  :dir_mode   => :normal,
  :dir        => 'log',
  :multiple   => true,
  :backtrace  => true,
  :log_output => true
})
