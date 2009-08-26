$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

# Standard Library:
require 'tmpdir'
require 'erb'

# Gems:
require 'sinatra'
require 'activerecord'
require 'json'
require 'daemons'
require 'rest_client'
require 'right_aws'

module CloudCrowd
  
  class App < Sinatra::Default
    set :root, File.expand_path(File.dirname(__FILE__) + '/..')
  end
  
  # Keep the version in sync with the gemspec.
  VERSION     = '0.0.1'
    
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
        Module.const_get(action_class)
      rescue NameError => e
        require "#{CloudCrowd::App.root}/actions/#{name}"
        retry
      end
    end
  end
  
end

# CloudCrowd:
require 'cloud_crowd/core_ext'
require 'cloud_crowd/models'
require 'cloud_crowd/asset_store'
require 'cloud_crowd/action'
require 'cloud_crowd/helpers'
require 'cloud_crowd/app'
