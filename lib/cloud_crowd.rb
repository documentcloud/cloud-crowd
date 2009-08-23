$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))


# Standard Library:
require 'tmpdir'

# Gems:
require 'sinatra'
require 'activerecord'
require 'json'
require 'daemons'
require 'rest_client'
require 'right_aws'

# CloudCrowd:
require 'cloud_crowd/models'
require 'cloud_crowd/helpers'
require 'cloud_crowd/app'


# SECRETS = YAML.load_file("#{RAILS_ROOT}/config/secrets.yml")[RAILS_ENV]

module CloudCrowd
  
  # Load configuration.
  CONFIG  = YAML.load_file("#{RAILS_ROOT}/config/cloud_crowd.yml")[RAILS_ENV]
  
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
  
  # Return the display-ready status.
  def self.display_status(status)
    DISPLAY_STATUS_MAP[status]
  end
  
end