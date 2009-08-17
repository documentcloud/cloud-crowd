module Houdini
  
  CONFIG = YAML.load_file("#{RAILS_ROOT}/config/houdini.yml")[RAILS_ENV]
  
  # All the possible statuses for Jobs and WorkUnits
  PROCESSING  = 1
  COMPLETE    = 2
  ERROR       = 3
  
end