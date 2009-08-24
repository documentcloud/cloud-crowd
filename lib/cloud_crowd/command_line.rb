module CloudCrowd
  class CommandLine
    
    def initialize
      command = ARGV.shift
      case command
      when 'console' then load_console
      when 'server'  then start_server
      when 'workers' then run_workers
      else                usage
      end
    end
    
    def load_console
      require 'irb'
      require 'irb/completion'
      require 'rubygems'
      require File.dirname(__FILE__) + '/../cloud-crowd'
      
      CloudCrowd.configure('config.yml')
      CloudCrowd.configure_database('database.yml')
      IRB.start
    end
    
    def start_server
      
    end
    
    def run_workers
      
    end
    
    def usage
      
    end
    
  end
end