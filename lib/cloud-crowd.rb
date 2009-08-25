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
    
  # All the possible statuses for Jobs and WorkUnits
  PROCESSING  = 1
  PENDING     = 2
  SUCCEEDED   = 3
  FAILED      = 4
  
  # A work unit is considered to be complete if it succeeded or if it failed.
  COMPLETE    = [SUCCEEDED, FAILED]
  
  # A work unit is considered incomplete if it's pending or being processed.
  INCOMPLETE  = [PENDING, PROCESSING]
  
  # Mapping of statuses to their display strings.
  DISPLAY_STATUS_MAP = {
    1 => 'processing', 2 => 'pending', 3 => 'succeeded', 4 => 'failed'
  }
  
  class << self
    attr_reader :config
    
    def configure(config_path)
      @config = YAML.load_file(config_path)
    end

    def configure_database(config_path)
      configuration = YAML.load_file(config_path)
      ActiveRecord::Base.establish_connection(configuration)
    end

    def display_status(status)
      DISPLAY_STATUS_MAP[status]
    end
  end
  
end

# CloudCrowd:
require 'cloud_crowd/models'
require 'cloud_crowd/asset_store'
require 'cloud_crowd/action'
require 'cloud_crowd/helpers'
require 'cloud_crowd/app'
