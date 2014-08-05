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
  cleanup       Removes jobs that were finished over --days (7 by default) ago

  server -d [start | stop | restart]    Servers and nodes can be launched as
  node -d [start | stop | restart]      daemons, then stopped or restarted.

Options:
    EOS

    # Creating a CloudCrowd::CommandLine runs from the contents of ARGV.
    def initialize
      parse_options
      command     = ARGV.shift
      subcommand  = ARGV.shift
      case command
      when 'console'      then run_console
      when 'server'       then run_server(subcommand)
      when 'node'         then run_node(subcommand)
      when 'load_schema'  then run_load_schema
      when 'install'      then run_install(subcommand)
      when 'cleanup'      then run_cleanup
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
      connect_to_database true
      CloudCrowd::Server # Preload server to autoload classes.
      Object.send(:include, CloudCrowd)
      IRB.start
    end

    # `crowd server` can either 'start', 'stop', or 'restart'.
    def run_server(subcommand)
      load_code
      subcommand ||= 'start'
      case subcommand
      when 'start'    then start_server
      when 'stop'     then stop_server
      when 'restart'  then restart_server
      end
    end

    # Convenience command for quickly spinning up the central server. More
    # sophisticated deployments, load-balancing across multiple app servers,
    # should use the config.ru rackup file directly. This method will start
    # a single Thin server.
    def start_server
      port        = @options[:port] || 9173
      daemonize   = @options[:daemonize] ? '-d' : ''
      log_path    = CloudCrowd.log_path('server.log')
      pid_path    = CloudCrowd.pid_path('server.pid')
      rackup_path = File.expand_path("#{@options[:config_path]}/config.ru")
      FileUtils.mkdir_p(CloudCrowd.log_path) if @options[:daemonize] && !File.exists?(CloudCrowd.log_path)
      puts "Starting CloudCrowd Central Server (#{VERSION}) on port #{port}..."
      exec "thin -e #{@options[:environment]} -p #{port} #{daemonize} --tag cloud-crowd-server --log #{log_path} --pid #{pid_path} -R #{rackup_path} start"
    end

    # Stop the daemonized central server, if it exists.
    def stop_server
      Thin::Server.kill(CloudCrowd.pid_path('server.pid'), 0)
    end

    # Restart the daemonized central server.
    def restart_server
      stop_server
      sleep 1
      start_server
    end

    # `crowd node` can either 'start', 'stop', or 'restart'.
    def run_node(subcommand)
      load_code
      ENV['RACK_ENV'] = @options[:environment]
      case (subcommand || 'start')
      when 'start'    then start_node
      when 'stop'     then stop_node
      when 'restart'  then restart_node
      end
    end

    # Launch a Node. Please only run a single node per machine. The Node process
    # will be long-lived, although its workers will come and go.
    def start_node
      @options[:port] ||= Node::DEFAULT_PORT
      puts "Starting CloudCrowd Node (#{VERSION}) on port #{@options[:port]}..."
      Node.new(@options)
    end

    # If the daemonized Node is running, stop it.
    def stop_node
      Thin::Server.kill CloudCrowd.pid_path('node.pid')
    end

    # Restart the daemonized Node, if it exists.
    def restart_node
      stop_node
      sleep 1
      start_node
    end

    # Load in the database schema to the database specified in 'database.yml'.
    def run_load_schema
      load_code
      connect_to_database(false)
      require 'cloud_crowd/schema.rb'
    end

    # Install the required CloudCrowd configuration files into the specified
    # directory, or the current one.
    def run_install(install_path)
      require 'fileutils'
      install_path ||= '.'
      FileUtils.mkdir_p install_path unless File.exists?(install_path)
      install_file "#{CC_ROOT}/config/config.example.yml", "#{install_path}/config.yml"
      install_file "#{CC_ROOT}/config/config.example.ru", "#{install_path}/config.ru"
      install_file "#{CC_ROOT}/config/database.example.yml", "#{install_path}/database.yml"
      install_file "#{CC_ROOT}/actions", "#{install_path}/actions", true
    end

    # Clean up all Jobs in the CloudCrowd database older than --days old.
    def run_cleanup
      load_code
      connect_to_database(true)
      Job.cleanup_all(:days => @options[:days])
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
    # Valid options are: --config --port --environment --tag --daemonize --days.
    def parse_options
      @options = {
        :environment  => 'production',
        :config_path  => ENV['CLOUD_CROWD_CONFIG'] || '.',
        :daemonize    => false
      }
      @option_parser = OptionParser.new do |opts|
        opts.on('-c', '--config PATH', 'path to configuration directory') do |conf_path|
          @options[:config_path] = conf_path
        end
        opts.on('-p', '--port PORT', 'port number for server (central or node)') do |port_num|
          @options[:port] = port_num
        end
        opts.on('-e', '--environment ENV', 'server environment (defaults to production)') do |env|
          @options[:environment] = env
        end
        opts.on('-t', '--tag TAG', 'tag a node with a name') do |tag|
          @options[:tag] = tag
        end
        opts.on('-d', '--daemonize', 'run as a background daemon') do |daemonize|
          @options[:daemonize] = daemonize
        end
        opts.on('--days NUM_DAYS', 'grace period before cleanup (7 by default)') do |days|
          @options[:days] = days.to_i if days.match(/\A\d+\Z/)
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
      puts "installed #{dest}" unless ENV['RACK_ENV'] == 'test'
    end

  end
end
