#!/usr/bin/env ruby -rubygems

require 'restclient'
require 'json'

# Let's count all the words in this file.

RestClient.post('http://localhost:9173/jobs', 
  {:job => {
    'action' => 'word_count',
    'inputs' => ["file://#{File.expand_path(__FILE__)}"]
  }.to_json}
)
