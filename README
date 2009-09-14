=                                                                               
           _  _                                                                
          ( `   )_                                                             
         (    )    `)                                                          
       (_   (_ .  _) _)                                                        
                                      _                                        
                                     (  )                                      
      _ .                         ( `  ) . )                                   
    (  _ )_                      (_, _(  ,_)_)                                 
  (_  _(_ ,)                                                                   
                                                                               
           _  _               ___ _             _  ___                   _     
          ( `   )_           / __| |___ _  _ __| |/ __|_ _ _____ __ ____| |    
         (    )    `)       | (__| / _ \ || / _` | (__| '_/ _ \ V  V / _` |    
       (_   (_ .  _) _)      \___|_\___/\_,_\__,_|\___|_| \___/\_/\_/\__,_|    
                                                                               
                                                     _                         
                                                    (  )                       
                  _, _ .                         ( `  ) . )                    
                 ( (  _ )_                      (_, _(  ,_)_)                  
               (_(_  _(_ ,)                                                    
                                                                               
                                                                               
                                                                               
  ~ CloudCrowd ~

    * Parallel processing for the rest of us
    * Write your scripts in Ruby
    * Built for Amazon EC2 and S3
    * split -> process -> merge
    * As easy as `gem install cloud-crowd`

    Well-suited for:
    
    * Generating or resizing images.
    * Encoding video.
    * Running text extraction or OCR on PDFs.
    * Migrating a large file set or database.
    * Web scraping.
    
    
  ~ Documentation ~
  
    Wiki: http://wiki.github.com/documentcloud/cloud-crowd
    Rdoc: http://rdoc.info/projects/documentcloud/cloud-crowd
  
  
  ~ Getting started ~
  
    # Install the gem.
    
      >> sudo gem install cloud-crowd
    
    # Install the CloudCrowd configuration files to a location of your choosing.
    
      >> crowd install ~/config/cloud-crowd
    
    # Now, you can use the full complement of `crowd` commands from inside of
    # this configuration directory. To see the available commands:
    
      >> crowd --help
    
    # Edit the configuration files to your satisfaction, add AWS credentials, 
    # and then load the CloudCrowd schema into your configured database.
    
      >> mate ~/config/cloud-crowd/config.yml
      >> mate ~/config/cloud-crowd/database.yml
      >> crowd load_schema
    
    # Write your actions, and install them into the 'actions' subdirectory.
    # CloudCrowd comes with some default actions as an example.
    
    # To launch the central server (make sure that you include its location
    # in config.yml), either:
    
      >> crowd server
    
    # or:
    
      >> thin -R config.ru --servers 3 -e production start
    
    # Any server that supports Rack should work with the rackup file.
    
    # Then, to spin up 10 workers:
    
      >> crowd workers start -n 10
    
    # To spin up workers remotely, install the 'cloud-crowd' gem, and copy over
    # your configuration directory.
    
    # At this point you can visit your server console at localhost:9173 to 
    # view all of your workers, ready for action.
  