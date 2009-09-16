# The Grand Central of code loading...

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

# Common Gems:
require 'rubygems'
gem 'activerecord'
gem 'json'
gem 'rest-client'
gem 'right_aws'
gem 'sinatra'
gem 'thin'

# Autoloading for all the pieces which may or may not be needed:
autoload :ActiveRecord, 'activerecord'
autoload :Benchmark,    'benchmark'
autoload :Digest,       'digest'
autoload :ERB,          'erb'
autoload :FileUtils,    'fileutils'
autoload :JSON,         'json'
autoload :RestClient,   'restclient'
autoload :RightAws,     'right_aws'
autoload :Sinatra,      'sinatra'
autoload :Socket,       'socket'
autoload :Thin,         'thin'
autoload :YAML,         'yaml'

# Common code which should really be required in every circumstance.
require 'cloud_crowd/exceptions'

module CloudCrowd
  
  # Autoload all the CloudCrowd internals.
  autoload :Action,       'cloud_crowd/action'
  autoload :AssetStore,   'cloud_crowd/asset_store'
  autoload :Helpers,      'cloud_crowd/helpers'
  autoload :Inflector,    'cloud_crowd/inflector'
  autoload :Job,          'cloud_crowd/models'
  autoload :Node,         'cloud_crowd/node'
  autoload :NodeRecord,   'cloud_crowd/models'
  autoload :Server,       'cloud_crowd/server'
  autoload :Worker,       'cloud_crowd/worker'
  autoload :WorkUnit,     'cloud_crowd/models'
  
  # Root directory of the CloudCrowd gem.
  ROOT        = File.expand_path(File.dirname(__FILE__) + '/..')
  
  # Keep this version in sync with the gemspec.
  VERSION     = '0.1.1'
    
  # A Job is processing if its WorkUnits are in the queue to be handled by nodes.
  PROCESSING  = 1
  
  # A Job has succeeded if all of its WorkUnits have finished successfully.
  SUCCEEDED   = 2
  
  # A Job has failed if even a single one of its WorkUnits has failed (they may
  # be attempted multiple times on failure, however).
  FAILED      = 3
  
  # A Job is splitting if it's in the process of dividing its inputs up into
  # multiple WorkUnits.
  SPLITTING   = 4
  
  # A Job is merging if it's busy collecting all of its successful WorkUnits
  # back together into the final result.
  MERGING     = 5
  
  # A Job is considered to be complete if it succeeded or if it failed.
  COMPLETE    = [SUCCEEDED, FAILED]
  
  # A Job is considered incomplete if it's being processed, split up or merged.
  INCOMPLETE  = [PROCESSING, SPLITTING, MERGING]
  
  # Mapping of statuses to their display strings.
  DISPLAY_STATUS_MAP = ['unknown', 'processing', 'succeeded', 'failed', 'splitting', 'merging']
  
  class << self
    attr_reader :config
    
    # Configure CloudCrowd by passing in the path to <tt>config.yml</tt>.
    def configure(config_path)
      @config_path = File.expand_path(File.dirname(config_path))
      @config = YAML.load_file(config_path)
    end

    # Configure the CloudCrowd central database (and connect to it), by passing
    # in a path to <tt>database.yml</tt>. The file should use the standard 
    # ActiveRecord connection format.
    def configure_database(config_path)
      configuration = YAML.load_file(config_path)
      ActiveRecord::Base.establish_connection(configuration)
    end
    
    # Get a reference to the central server, including authentication if 
    # configured.
    def central_server
      return @central_server if @central_server
      params = [CloudCrowd.config[:central_server]]
      params += [CloudCrowd.config[:login], CloudCrowd.config[:password]] if CloudCrowd.config[:http_authentication]
      @central_server = RestClient::Resource.new(*params)
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
      @actions = {}
      default_actions   = Dir["#{ROOT}/actions/*.rb"]
      installed_actions = Dir["#{@config_path}/actions/*.rb"]
      custom_actions    = Dir["#{CloudCrowd.config[:actions_path]}/*.rb"]
      (default_actions + installed_actions + custom_actions).each do |path|
        name = File.basename(path, File.extname(path))
        require path
        @actions[name] = Module.const_get(Inflector.camelize(name))
      end
      @actions
    end
  end
  
end