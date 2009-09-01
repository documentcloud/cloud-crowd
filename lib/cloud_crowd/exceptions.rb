module CloudCrowd
  
  # Base Error class which all custom CloudCrowd exceptions inherit from.
  class Error < RuntimeError #:nodoc:
  end
  
  # ActionNotFound is raised when a job is created for an action that doesn't 
  # exist.
  class ActionNotFound < Error #:nodoc:
  end
  
  # StatusUnspecified is raised when a WorkUnit returns without a valid
  # status code.
  class StatusUnspecified < Error #:nodoc:
  end
  
end