#!/usr/bin/env ruby -rubygems

require 'restclient'
require 'json'

# This example demonstrates the GraphicsMagick action by taking in a list of
# five images, and producing annotated, blurred, and black and white versions
# of each image. See actions/graphics_magick.rb

RestClient.post('http://localhost:9173/jobs', 
  {:job => {
  
    'action' => 'graphics_magick',
    
    'inputs' => [
      'http://www.sci-fi-o-rama.com/wp-content/uploads/2008/10/dan_mcpharlin_the_land_of_sleeping_things.jpg',
      'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread01.jpg',
      'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread03.jpg',
      'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread02.jpg',
      'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/02/dan_mcpharlin_untitled.jpg'
    ],
    
    'options' => {
      'steps' => [{
        'name'      => 'annotated',
        'command'   => 'convert',
        'options'   => '-font helvetica -fill red -draw "font-size 35; text 75,75 CloudCrowd!"',
        'extension' => 'jpg'
      },{
        'name'      => 'blurred',
        'command'   => 'convert',
        'options'   => '-blur 10x5',
        'extension' => 'png'
      },{
        'name'      => 'bw', 
        'input'     => 'blurred',
        'command'   => 'convert', 
        'options'   => '-monochrome', 
        'extension' => 'jpg'
      }]
    }
    
  }.to_json}
)