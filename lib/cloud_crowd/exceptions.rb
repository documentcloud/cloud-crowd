module CloudCrowd
  
  # Base Error class which all custom CloudCrowd exceptions inherit from.
  # Rescuing CloudCrowd::Error (or RuntimeError) will get all custom exceptions.
  # If your cluster is correctly configured, you should never expect to see any
  # of these.
  class Error < RuntimeError
    
    # ActionNotFound is raised when a job is created for an action that doesn't 
    # exist.
    class ActionNotFound < Error
    end
  
    # StorageNotFound is raised when config.yml specifies a storage back-end that
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
    
    # MissingConfiguration is raised when we're trying to run a method that
    # needs configuration not present in config.yml.
    class MissingConfiguration < Error
    end
    
    # CommandFailed is raised when an action shells out, and the external 
    # command returns a non-zero exit code.
    class CommandFailed < Error
      attr_reader :exit_code
      
      def initialize(message, exit_code)
        super(message)
        @exit_code = exit_code
      end
    end
    
  end
  
end