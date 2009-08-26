require 'optparse'

module CloudCrowd
  class CommandLine
    
    # Configuration files required for the `crowd` command to function.
    CONFIG_FILES = ['config.yml', 'config.ru', 'database.yml']
    
    WORKER_RUNNER = File.expand_path("#{File.dirname(__FILE__)}/runner.rb")
    
    # Creating a CloudCrowd::CommandLine runs from the contents of ARGV.
    def initialize
      parse_options
      command = ARGV.shift
      case command
      when 'console'      then run_console
      when 'server'       then run_server
      when 'workers'      then run_workers_command
      when 'load_schema'  then run_load_schema
      when 'install'      then run_install
      else                     usage
      end
    end
    
    # Spin up an IRB session with the CloudCrowd code loaded in, and a database
    # connection established. The equivalent of Rails' `script/console`.
    def run_console
      require 'irb'
      require 'irb/completion'
      load_code
      connect_to_database
      IRB.start
    end
    
    # Convenience command for quickly spinning up the central server. More 
    # sophisticated deployments, load-balancing across multiple app servers, 
    # should use the config.ru rackup file directly. This method will start
    # a single Thin server, if Thin is installed, otherwise the rackup defaults 
    # (Mongrel, falling back to WEBrick). The equivalent of Rails' script/server.
    def run_server
      require 'rubygems'
      rackup_path = File.expand_path('config.ru')
      if Gem.available? 'thin'
        exec "thin start -R #{rackup_path} -e production -p #{@options[:port]}"
      else
        
      end
    end
    
    def run_load_schema
      load_code
      connect_to_database
      require 'cloud_crowd/schema.rb'
    end
    
    def run_install
      require 'fileutils'
      install_path = ARGV.shift
      cc_root = File.dirname(__FILE__) + '/../..'
      FileUtils.mkdir_p install_path unless File.exists?(install_path)
      FileUtils.cp "#{cc_root}/config/config.example.ru", "#{install_path}/config.ru"
      FileUtils.cp "#{cc_root}/config/config.example.yml", "#{install_path}/config.yml"
      FileUtils.cp "#{cc_root}/config/database.example.yml", "#{install_path}/database.yml"
      FileUtils.cp_r "#{cc_root}/actions", "#{install_path}/actions"
    end
    
    def run_workers_command
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
    
    
    private
    
    # Check for configuration files, either in the current directory, or in
    # the CLOUD_CROWD_CONFIG environment variable. Exit if they're not found.
    def ensure_config
      return if @config_found
      config_dir = ENV['CLOUD_CROWD_CONFIG'] || '.'
      Dir.chdir config_dir
      CONFIG_FILES.all? {|f| File.exists? f } ? @config_dir = true : config_not_found
    end
    
    # Parse all options for all actions.
    # TODO: Think about parsing options per sub-command separately.
    def parse_options
      @options = {
        :db_config => 'database.yml',
        :port      => 9173,
      }
      opts = OptionParser.new do |opts|
        opts.on('-n', '--num-workers NUM', OptionParser::DecimalInteger, 'Number of Worker Processes') do |num|
          @options[:num_workers] = num
        end
        opts.on('-d', '--database-config PATH', 'Database Configuration Path') do |conf_path|
          @options[:db_config] = conf_path
        end
        opts.on('-p', '--port PORT', 'Central Server Port Number') do |port_num|
          @options[:port] = port_num
        end
      end
      opts.parse(ARGV)
    end
    
    # Load in the CloudCrowd module code, dependencies, lib files and models.
    # Not all commands require this.
    def load_code
      ensure_config
      require 'rubygems'
      require File.dirname(__FILE__) + '/../cloud-crowd'
      CloudCrowd.configure('config.yml')
    end
    
    # Establish a connection to the central server's database. Not all commands
    # require this.
    def connect_to_database
      CloudCrowd.configure_database(@options[:db_config])
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