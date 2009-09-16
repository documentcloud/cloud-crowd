#!/usr/bin/env ruby

# This rackup script can be used to start the central CloudCrowd server
# using any Rack-compliant server handler. For example, start up three servers 
# with a specified port number, using Thin:
#
# thin start -R config.ru --servers 3
#
# Or a single server with Unicorn:
#
# unicorn config.ru
#


require 'rubygems'
require 'cloud-crowd'

CloudCrowd.configure(File.dirname(__FILE__) + '/config.yml')
CloudCrowd.configure_database(File.dirname(__FILE__) + '/database.yml')

map '/' do
  run CloudCrowd::Server
end