#!/usr/bin/env ruby
require 'rubygems'
require 'cloud_crowd'

CloudCrowd.new(File.dirname(__FILE__) + '/cloud_crowd.yml')

map '/' do
  run CloudCrowd::App
end

CloudCrowd