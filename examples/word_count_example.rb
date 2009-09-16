#!/usr/bin/env ruby -rubygems

require 'restclient'
require 'json'

# Let's count all the words in Shakespeare.

RestClient.post('http://localhost:9173/jobs', 
  {:job => {
  
    'action' => 'word_count',
    
    'inputs' => [
      'http://www.gutenberg.org/dirs/etext97/1ws3010.txt',  # All's Well That Ends Well
      'http://www.gutenberg.org/dirs/etext99/1ws3511.txt',  # Anthony and Cleopatra
      'http://www.gutenberg.org/dirs/etext97/1ws2510.txt',  # As You Like It
      'http://www.gutenberg.org/dirs/etext97/1ws0610.txt',  # The Comedy of Errors
      'http://www.gutenberg.org/dirs/etext99/1ws3911.txt',  # Cymbeline
      'http://www.gutenberg.org/dirs/etext00/0ws2610.txt',  # Hamlet
      'http://www.gutenberg.org/dirs/etext00/0ws1910.txt',  # Henry IV
      'http://www.gutenberg.org/dirs/etext99/1ws2411.txt',  # Julius Caesar
      'http://www.gutenberg.org/dirs/etext98/2ws3310.txt',  # King Lear
      'http://www.gutenberg.org/dirs/etext99/1ws1211j.txt', # Love's Labour's Lost
      'http://www.gutenberg.org/dirs/etext98/2ws3410.txt',  # Macbeth
      'http://www.gutenberg.org/dirs/etext98/2ws1810.txt',  # The Merchant of Venice
      'http://www.gutenberg.org/dirs/etext99/1ws1711.txt',  # Midsummer Night's Dream
      'http://www.gutenberg.org/dirs/etext98/3ws2210.txt',  # Much Ado About Nothing
      'http://www.gutenberg.org/dirs/etext00/0ws3210.txt',  # Othello
      'http://www.gutenberg.org/dirs/etext98/2ws1610.txt',  # Romeo and Juliet
      'http://www.gutenberg.org/dirs/etext98/2ws1010.txt',  # The Taming of the Shrew
      'http://www.gutenberg.org/dirs/etext99/1ws4111.txt',  # The Tempest
      'http://www.gutenberg.org/dirs/etext00/0ws0910.txt',  # Titus Andronicus
      'http://www.gutenberg.org/dirs/etext99/1ws2911.txt',  # Troilus and Cressida
      'http://www.gutenberg.org/dirs/etext98/3ws2810.txt',  # Twelfth Night
      'http://www.gutenberg.org/files/1539/1539.txt'        # The Winter's Tale
    ]
    
  }.to_json}
)

# With 23 Workers running, and over Wifi, it counted all the words in 5.5 secs.
# On a fast internet connection, you may not even see this job show up.
