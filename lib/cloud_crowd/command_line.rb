require 'optparse'

module CloudCrowd
  class CommandLine
    
    # Configuration files required for the `crowd` command to function.
    CONFIG_FILES = ['config.yml', 'config.ru', 'database.yml']
    
    # Reference the absolute path to the root.
    CC_ROOT = File.expand_path(File.dirname(__FILE__) + '/../..')
    
    # Command-line banner for the usage message.
    BANNER = <<-EOS
CloudCrowd is a MapReduce-inspired Parallel Processing System for Ruby.

Wiki: http://wiki.github.com/documentcloud/cloud-crowd
Rdoc: http://rdoc.info/projects/documentcloud/cloud-crowd

Usage: crowd COMMAND OPTIONS

Commands:
  install       Install the CloudCrowd configuration files to the specified directory
  server        Start up the central server (requires a database)
  node          Start up a worker node (only one node per machine, please)
  console       Launch a CloudCrowd console, connected to the central database
  load_schema   Load the schema into the database specified by database.yml

Options:
    EOS
    
    # Creating a CloudCrowd::CommandLine runs from the contents of ARGV.
    def initialize
      parse_options
      command = ARGV.shift
      case command
      when 'console'      then run_console
      when 'server'       then run_server
      when 'node'         then run_node
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
      require 'pp'
      load_code
      connect_to_database(true)
      IRB.start
    end
    
    # Convenience command for quickly spinning up the central server. More 
    # sophisticated deployments, load-balancing across multiple app servers, 
    # should use the config.ru rackup file directly. This method will start
    # a single Thin server, if Thin is installed, otherwise the rackup defaults 
    # (Mongrel, falling back to WEBrick). The equivalent of Rails' script/server.
    def run_server
      ensure_config
      @options[:port] ||= 9173
      require 'rubygems'
      rackup_path = File.expand_path("#{@options[:config_path]}/config.ru")
      if Gem.available? 'thin'
        exec "thin -e #{@options[:environment]} -p #{@options[:port]} -R #{rackup_path} start"
      else
        exec "rackup -E #{@options[:environment]} -p #{@options[:port]} #{rackup_path}"
      end
    end
    
    # Launch a Node. Please only run a single node per machine. The Node process
    # will be long-lived, although its workers will come and go.
    def run_node
      ENV['RACK_ENV'] = @options['environment']
      load_code
      Node.new(@options[:port])
    end
    
    # Load in the database schema to the database specified in 'database.yml'.
    def run_load_schema
      load_code
      connect_to_database(false)
      require 'cloud_crowd/schema.rb'
    end
    
    # Install the required CloudCrowd configuration files into the specified
    # directory, or the current one.
    def run_install
      require 'fileutils'
      install_path = ARGV.shift || '.'
      FileUtils.mkdir_p install_path unless File.exists?(install_path)
      install_file "#{CC_ROOT}/config/config.example.yml", "#{install_path}/config.yml"
      install_file "#{CC_ROOT}/config/config.example.ru", "#{install_path}/config.ru"
      install_file "#{CC_ROOT}/config/database.example.yml", "#{install_path}/database.yml"
      install_file "#{CC_ROOT}/actions", "#{install_path}/actions", true
    end
    
    # Print `crowd` usage.
    def usage
      puts "\n#{@option_parser}\n"
    end
    
    
    private
    
    # Check for configuration files, either in the current directory, or in
    # the CLOUD_CROWD_CONFIG environment variable. Exit if they're not found.
    def ensure_config
      return if @config_found
      found = CONFIG_FILES.all? {|f| File.exists? "#{@options[:config_path]}/#{f}" }
      found ? @config_dir = true : config_not_found
    end
    
    # Parse all options for all commands.
    def parse_options
      @options = {
        :environment  => 'production',
        :config_path  => ENV['CLOUD_CROWD_CONFIG'] || '.'
      }
      @option_parser = OptionParser.new do |opts|
        opts.on('-c', '--config PATH', 'path to configuration directory') do |conf_path|
          @options[:config_path] = conf_path
        end
        opts.on('-p', '--port PORT', 'port number for server (central or node)') do |port_num|
          @options[:port] = port_num
        end
        opts.on('-e', '--environment ENV', 'server environment (sinatra)') do |env|
          @options[:environment] = env
        end
        opts.on_tail('-v', '--version', 'show version') do
          require "#{CC_ROOT}/lib/cloud-crowd"
          puts "CloudCrowd version #{VERSION}"
          exit
        end
      end
      @option_parser.banner = BANNER
      @option_parser.parse!(ARGV)
    end
    
    # Load in the CloudCrowd module code, dependencies, lib files and models.
    # Not all commands require this.
    def load_code
      ensure_config
      require "#{CC_ROOT}/lib/cloud-crowd"
      CloudCrowd.configure("#{@options[:config_path]}/config.yml")
    end
    
    # Establish a connection to the central server's database. Not all commands
    # require this.
    def connect_to_database(validate_schema)
      require 'cloud_crowd/models'
      CloudCrowd.configure_database("#{@options[:config_path]}/database.yml", validate_schema)
    end
    
    # Exit with an explanation if the configuration files couldn't be found.
    def config_not_found
      puts "`crowd` can't find the CloudCrowd configuration directory. Please use `crowd -c path/to/config`, or run `crowd` from inside of the configuration directory itself."
      exit(1)
    end
    
    # Install a file and log the installation. If we're overwriting a file, 
    # offer a chance to back out.
    def install_file(source, dest, is_dir=false)
      if File.exists?(dest)
        print "#{dest} already exists. Overwrite it? (yes/no) "
        return unless ['y', 'yes', 'ok'].include? gets.chomp.downcase
      end
      is_dir ? FileUtils.cp_r(source, dest) : FileUtils.cp(source, dest)
      puts "installed #{dest}"
    end
    
  end
end