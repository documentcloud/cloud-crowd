module Dogpile
  
  CONFIG = YAML.load_file("#{RAILS_ROOT}/config/dogpile.yml")[RAILS_ENV]
  
  # All the possible statuses for Jobs and WorkUnits
  PROCESSING  = 1
  COMPLETE    = 2
  PENDING     = 3
  FAILED      = 4
  
  # A work unit is considered to be done if it's complete or if it failed.
  DONE        = [COMPLETE, FAILED]
  
  # A work unit is considered incomplete if it's pending or being processed.
  INCOMPLETE  = [PENDING, PROCESSING]
  
  # Mapping of statuses to their display strings.
  DISPLAY_STATUS_MAP = {
    1 => 'processing', 2 => 'complete', 3 => 'pending', 4 => 'failed'
  }
  
  def self.display_status(status)
    DISPLAY_STATUS_MAP[status]
  end
  
end