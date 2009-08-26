require 'optparse'

module CloudCrowd
  class CommandLine
    
    CONFIG_FILES = ['config.yml', 'config.ru', 'database.yml']
    
    WORKER_RUNNER = File.expand_path("#{File.dirname(__FILE__)}/../daemons/runner.rb")
    
    def initialize
      parse_options
      command = ARGV.shift
      case command
      when 'console'      then load_console
      when 'server'       then start_server
      when 'workers'      then control_workers
      when 'load_schema'  then load_schema
      when 'install'      then install_configuration
      else                     usage
      end
    end
    
    def ensure_config
      return if @config_found
      config_dir = ENV['CLOUD_CROWD_CONFIG'] || '.'
      Dir.chdir config_dir
      CONFIG_FILES.all? {|f| File.exists? f } ? @config_dir = true : config_not_found
    end
    
    def parse_options
      @options = {}
      opts = OptionParser.new do |opts|
        opts.on('-n', '--num-workers NUM', OptionParser::DecimalInteger, 'Number of Worker Processes') do |num|
          @options[:num_workers] = num
        end
        opts.on('-d', '--database-config PATH', 'Database Configuration Path') do |conf_path|
          @options[:db_config] = conf_path
        end
      end
      opts.parse(ARGV)
    end
    
    def load_code
      ensure_config
      require 'rubygems'
      require File.dirname(__FILE__) + '/../cloud-crowd'
      CloudCrowd.configure('config.yml')
    end
    
    def load_console
      require 'irb'
      require 'irb/completion'
      load_code
      connect_to_database
      IRB.start
    end
    
    def start_server
      
    end
    
    def load_schema
      load_code
      connect_to_database
      require 'cloud_crowd/schema.rb'
    end
    
    def install_configuration
      require 'fileutils'
      install_path = ARGV.shift
      cc_root = File.dirname(__FILE__) + '/../..'
      FileUtils.mkdir_p install_path unless File.exists?(install_path)
      FileUtils.cp "#{cc_root}/config/config.example.ru", "#{install_path}/config.ru"
      FileUtils.cp "#{cc_root}/config/config.example.yml", "#{install_path}/config.yml"
      FileUtils.cp "#{cc_root}/config/database.example.yml", "#{install_path}/database.yml"
      FileUtils.cp_r "#{cc_root}/actions", "#{install_path}/actions"
    end
    
    def control_workers
      ensure_config
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
      load_code
      num_workers = @options[:num_workers] || CloudCrowd.config[:num_workers]
      num_workers.times do
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
    
    def connect_to_database
      CloudCrowd.configure_database(@options[:db_config] || 'database.yml')
    end
    
    def config_not_found
      puts "crowd` can't find the CloudCrowd configuration directory. Please either run 'crowd' from inside of the directory, or add a CLOUD_CROWD_CONFIG variable to your environment."
      exit(1)
    end
    
    def usage
      puts 'Usage: lorem ipsum dolor sit amet...'
    end
    
    def worker_usage
      puts 'Use the workers like: lorem ipsum dolor sit amet...'
    end
    
  end
end