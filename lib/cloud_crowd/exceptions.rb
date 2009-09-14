module CloudCrowd
  
  # Base Error class which all custom CloudCrowd exceptions inherit from.
  # Rescuing CloudCrowd::Error (or RuntimeError) will get all custom exceptions.
  class Error < RuntimeError
    
    # ActionNotFound is raised when a job is created for an action that doesn't 
    # exist.
    class ActionNotFound < Error
    end
  
    # StorageNotFound is raised when config.yml specifies a storage back end that
    # doesn't exist.
    class StorageNotFound < Error
    end
    
    # If the AssetStore can't write to its scratch directory.
    class StorageNotWritable < Error
    end
    
    # StatusUnspecified is raised when a WorkUnit returns without a valid
    # status code.
    class StatusUnspecified < Error
    end
    
  end
  
end