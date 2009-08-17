module Houdini
  
  # Base Houdini::Action class. Override this with your custom action steps.
  class Action
    
    def run
      raise NotImplementedError.new("Houdini::Actions must override 'run' with their own processing code.")
    end
    
    def pre_process
      
    end
    
    def post_process
      
    end
    
    # If your Action has any cleanup to be performed (say, leftover files on S3)
    # override +cleanup+ with the appropriate garbage collection.
    def cleanup
      
    end
    
  end
  
end