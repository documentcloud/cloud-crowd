require 'optparse'

module CloudCrowd
  class CommandLine
    
    WORKER_RUNNER = "#{File.dirname(__FILE__)}/../daemons/runner.rb"
    
    def initialize
      parse_options
      command = ARGV.shift
      case command
      when 'console' then load_console
      when 'server'  then start_server
      when 'workers' then control_workers
      else                usage
      end
    end
    
    def parse_options
      @options = {}
      opts = OptionParser.new do |opts|
        opts.on('-n', '--num-workers NUM', OptionParser::DecimalInteger, 'Number of Worker Processes') do |num|
          @options[:num_workers] = num
        end
      end
      opts.parse(ARGV)
    end
    
    def load_code
      require File.dirname(__FILE__) + '/../cloud-crowd'
      CloudCrowd.configure('config.yml')
    end
    
    def load_console
      require 'irb'
      require 'irb/completion'
      require 'rubygems'
      load_code
      CloudCrowd.configure_database('database.yml')
      IRB.start
    end
    
    def start_server
      
    end
    
    def control_workers
      command = ARGV.shift
      case command
      when 'start'    then start_workers
      when 'stop'     then stop_workers
      when 'restart'  then stop_workers && start_workers
      when 'run'      then run_worker
      when 'status'   then show_worker_status
      else                 worker_usage
      end
    end
    
    def start_workers
      @options[:num_workers].times do
        `CLOUD_CROWD_CONFIG='#{File.expand_path('config.yml')}' ruby #{WORKER_RUNNER} start`
      end
    end
    
    def run_worker
      exec "CLOUD_CROWD_CONFIG='#{File.expand_path('config.yml')}' ruby #{WORKER_RUNNER} run"
    end
    
    def stop_workers
      `ruby #{WORKER_RUNNER} stop`
    end

    def show_worker_status
      puts `ruby #{WORKER_RUNNER} status`
    end
    
    def usage
      
    end
    
  end
end