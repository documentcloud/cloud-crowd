# The Grand Central of code loading...

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

# Common Gems:
require 'rubygems'
gem 'activerecord'
gem 'json'
gem 'sinatra'
gem 'thin'

# Autoloading for all the pieces which may or may not be needed:
autoload :ActiveRecord, 'active_record'
autoload :Benchmark,    'benchmark'
autoload :Digest,       'digest'
autoload :ERB,          'erb'
autoload :FileUtils,    'fileutils'
autoload :JSON,         'json'
autoload :RightAws,     'right_aws'
autoload :CloudFiles,   'cloudfiles'
autoload :Sinatra,      'sinatra'
autoload :Thin,         'thin'
autoload :YAML,         'yaml'

# Common code which should really be required in every circumstance.
require 'socket'
require 'net/http'
require 'cloud_crowd/version'
require 'cloud_crowd/exceptions'
require 'rest_client'
require 'pathname'
require 'active_model_serializers'
ActiveModel::Serializer.root = false

module CloudCrowd

  # Autoload all the CloudCrowd internals.
  autoload :Action,             'cloud_crowd/action'
  autoload :AssetStore,         'cloud_crowd/asset_store'
  autoload :CommandLine,        'cloud_crowd/command_line'
  autoload :Helpers,            'cloud_crowd/helpers'
  autoload :Inflector,          'cloud_crowd/inflector'
  autoload :MODELS,             'cloud_crowd/models'
  autoload :Job,                'cloud_crowd/models'
  autoload :BlackListedAction,  'cloud_crowd/models'
  autoload :Node,               'cloud_crowd/node'
  autoload :NodeRecord,         'cloud_crowd/models'
  autoload :Server,             'cloud_crowd/server'
  autoload :Worker,             'cloud_crowd/worker'
  autoload :WorkUnit,           'cloud_crowd/models'
  autoload :Dispatcher,         'cloud_crowd/dispatcher'

  # Increment the schema version when there's a backwards incompatible change.
  SCHEMA_VERSION = 5

  # Root directory of the CloudCrowd gem.
  ROOT           = File.expand_path(File.dirname(__FILE__) + '/..')

  # Default folder to log daemonized servers and nodes into.
  LOG_PATH       = 'log'

  # Default folder to contain the pids of daemonized servers and nodes.
  PID_PATH       = 'tmp/pids'

  # Minimum number of attempts per work unit.
  MIN_RETRIES    = 1

  # A Job is processing if its WorkUnits are in the queue to be handled by nodes.
  PROCESSING     = 1

  # A Job has succeeded if all of its WorkUnits have finished successfully.
  SUCCEEDED      = 2

  # A Job has failed if even a single one of its WorkUnits has failed (they may
  # be attempted multiple times on failure, however).
  FAILED         = 3

  # A Job is splitting if it's in the process of dividing its inputs up into
  # multiple WorkUnits.
  SPLITTING      = 4

  # A Job is merging if it's busy collecting all of its successful WorkUnits
  # back together into the final result.
  MERGING        = 5

  # A Job is considered to be complete if it succeeded or if it failed.
  COMPLETE       = [SUCCEEDED, FAILED]

  # A Job is considered incomplete if it's being processed, split up or merged.
  INCOMPLETE     = [PROCESSING, SPLITTING, MERGING]

  # Mapping of statuses to their display strings.
  DISPLAY_STATUS_MAP = ['unknown', 'processing', 'succeeded', 'failed', 'splitting', 'merging']

  class << self
    attr_reader :config
    attr_accessor :identity

    # Configure CloudCrowd by passing in the path to <tt>config.yml</tt>.
    def configure(config_path)
      @config_path = File.expand_path(File.dirname(config_path))
      @config = YAML.load(ERB.new(File.read(config_path)).result)
      @config[:database_config] = YAML.load(ERB.new(File.read("#{@config_path}/database.yml")).result)
      @config[:work_unit_retries] ||= MIN_RETRIES
      if @config[:actions_path]
        path = Pathname.new( @config[:actions_path] ).realpath
        $LOAD_PATH.unshift( path ) unless $LOAD_PATH.include?( path )
      end
    end

    # Configure the CloudCrowd central database (and connect to it), by passing
    # in a path to <tt>database.yml</tt>. The file should use the standard
    # ActiveRecord connection format.
    def configure_database(config_path, validate_schema=true)
      configuration = YAML.load(ERB.new(File.read(config_path)).result)
      ActiveRecord::Base.establish_connection(configuration)
      if validate_schema
        begin
          version = ActiveRecord::Base.connection.select_values('select max(version) from schema_migrations').first.to_i
        rescue
          version = 0
        end
        return true if version == SCHEMA_VERSION
        puts "Your database schema is out of date. Please use `crowd load_schema` to update it. This will wipe all the tables, so make sure that your jobs have a chance to finish first.\nexiting..."
        exit
      end
    end

    # Starts a new thread with a ActiveRecord connection_pool
    # and yields for peforming work inside the blocks
    def defer
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          yield
        end
      end
    end

    # Get a reference to the central server, including authentication if
    # configured.
    def central_server
      @central_server ||= RestClient::Resource.new(CloudCrowd.config[:central_server], CloudCrowd.client_options)
    end

    # The path that daemonized servers and nodes will log to.
    def log_path(log_file=nil)
      @log_path ||= config[:log_path] || LOG_PATH
      log_file ? File.join(@log_path, log_file) : @log_path
    end

    # The path in which daemonized servers and nodes will store their pids.
    def pid_path(pid_file=nil)
      @pid_path ||= config[:pid_path] || PID_PATH
      pid_file ? File.join(@pid_path, pid_file) : @pid_path
    end

    # The standard RestClient options for the central server talking to nodes,
    # as well as the other way around. There's a timeout of 5 seconds to open
    # a connection, and a timeout of 30 to finish reading it.
    def client_options
      return @client_options if @client_options
      @client_options = {
        :timeout => (self.server? ? config[:node_timeout] : config[:server_timeout]) || 30,
        :open_timeout => config[:open_timeout] || 5
      }
      if CloudCrowd.config[:http_authentication]
        @client_options[:user]      = CloudCrowd.config[:login]
        @client_options[:password]  = CloudCrowd.config[:password]
      end
      @client_options
    end

    # Return the displayable status name of an internal CloudCrowd status number.
    # (See the above constants).
    def display_status(status)
      DISPLAY_STATUS_MAP[status] || 'unknown'
    end

    # CloudCrowd::Actions are requested dynamically by name. Access them through
    # this actions property, which behaves like a hash. At load time, we
    # load all installed Actions and CloudCrowd's default Actions into it.
    # If you wish to have certain nodes be specialized to only handle certain
    # Actions, then install only those into the actions directory.
    def actions
      return @actions if @actions
      @actions = action_paths.inject({}) do |memo, path|
        path = Pathname.new(path)
        require path.relative? ? path.basename : path
        name = path.basename('.*').to_s
        memo[name] = Module.const_get( Inflector.camelize( name ) )
        memo
      end
    rescue NameError => e
      adjusted_message = "One of your actions failed to load. Please ensure that the name of your action class can be deduced from the name of the file. ex: 'word_count.rb' => 'WordCount'\n#{e.message}"
      raise NameError.new(adjusted_message, e.name)
    end

    # Retrieve the list of every installed Action for this node or server.
    def action_paths
      default_actions   = config[:disable_default_actions] ? [] : Dir["#{ROOT}/actions/*.rb"]
      installed_actions = Dir["#{@config_path}/actions/*.rb"]
      custom_actions    = CloudCrowd.config[:actions_path] ? Dir["#{CloudCrowd.config[:actions_path]}/*.rb"] : []
      default_actions + installed_actions + custom_actions
    end

    # Is this CloudCrowd instance a server? Useful for avoiding loading unneeded
    # code from actions.
    def server?
      @identity == :server
    end

    # Or is it a node?
    def node?
      @identity == :node
    end

    # Output a message with the current Timestamp prepended.
    # Sinatra will re-direct stdout to a log file located at "log_path"
    def log(message)
      printf("%-20s %s\n", Time.now.strftime("%F-%T:"), message)
    end

  end

end
