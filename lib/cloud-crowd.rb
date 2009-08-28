# The Grand Central of code loading...

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

# Common Gems:
require 'rubygems'
gem 'activerecord'
gem 'daemons'
gem 'json'
gem 'rest-client'
gem 'right_aws'
gem 'sinatra'

# Common CloudCrowd libs:
require 'cloud_crowd/core_ext'

# Autoloading for all the pieces which may or may not be needed:
autoload :ActiveRecord, 'activerecord'
autoload :Benchmark,    'benchmark'
autoload :Daemons,      'daemons'
autoload :ERB,          'erb'
autoload :FileUtils,    'fileutils'
autoload :JSON,         'json'
autoload :RestClient,   'rest_client'
autoload :RightAws,     'right_aws'
autoload :Sinatra,      'sinatra'
autoload :Socket,       'socket'
autoload :YAML,         'yaml'

module CloudCrowd
  
  # Autoload all the CloudCrowd classes which may not be required.
  autoload :App,        'cloud_crowd/app'
  autoload :Action,     'cloud_crowd/action'
  autoload :AssetStore, 'cloud_crowd/asset_store'
  autoload :Helpers,    'cloud_crowd/helpers'
  autoload :Job,        'cloud_crowd/models'
  autoload :WorkUnit,   'cloud_crowd/models'
  
  # Root directory of the CloudCrowd gem.
  ROOT        = File.expand_path(File.dirname(__FILE__) + '/..')
  
  # Keep the version in sync with the gemspec.
  VERSION     = '0.0.2'
    
  # A Job is processing if its WorkUnits in the queue to be handled by workers.
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
  
  # A work unit is considered to be complete if it succeeded or if it failed.
  COMPLETE    = [SUCCEEDED, FAILED]
  
  # A work unit is considered incomplete if it's being processed, split up or 
  # merged together.
  INCOMPLETE  = [PROCESSING, SPLITTING, MERGING]
  
  # Mapping of statuses to their display strings.
  DISPLAY_STATUS_MAP = {
    1 => 'processing', 2 => 'succeeded', 3 => 'failed', 4 => 'splitting', 5 => 'merging'
  }
  
  class << self
    attr_reader :config
    
    # Configure CloudCrowd by passing in the path to +config.yml+.
    def configure(config_path)
      @config_path = File.expand_path(File.dirname(config_path))
      @config = YAML.load_file(config_path)
    end

    # Configure the CloudCrowd central database (and connect to it), by passing
    # in a path to +database.yml+.
    def configure_database(config_path)
      configuration = YAML.load_file(config_path)
      ActiveRecord::Base.establish_connection(configuration)
    end

    # Return the readable status name of an internal CloudCrowd status number.
    def display_status(status)
      DISPLAY_STATUS_MAP[status]
    end
    
    # Some workers might not ever need to load all the installed actions,
    # so we lazy-load them. Think about a variant of this for installing and
    # loading actions into a running CloudCrowd cluster on the fly.
    def actions(name)
      action_class = name.camelize
      begin
        raise NameError, "can't find the #{action_class} Action" unless Module.constants.include?(action_class)
        Module.const_get(action_class)
      rescue NameError => e
        user_action     = "#{@config_path}/actions/#{name}"
        default_action  = "#{CloudCrowd::ROOT}/actions/#{name}"
        require user_action and retry    if File.exists? "#{user_action}.rb"
        require default_action and retry if File.exists? "#{default_action}.rb"
        raise e
      end
    end
  end
  
end