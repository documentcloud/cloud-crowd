#!/usr/bin/env ruby

require 'rubygems'
# require 'cloud-crowd'
require 'lib/cloud-crowd'

# CloudCrowd.new(File.dirname(__FILE__) + '/cloud_crowd.yml')

map '/' do
  run CloudCrowd::App
end