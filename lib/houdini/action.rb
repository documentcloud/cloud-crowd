module Houdini
  
  # Base Houdini::Action class. Override this with your custom action steps.
  class Action
    
    def initialize(input, options)
      @input, @options = input, options
      @job_id, @work_unit_id = options['job_id'], options['work_unit_id']
      FileUtils.mkdir_p(local_storage_path) unless File.exists?(local_storage_path)
    end
    
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
    
    
    protected
    
    def local_storage_path
      base        = '/tmp/houdini'
      action_part = underscore(self.class.to_s)
      job_part    = "job_#{@job_id}"
      unit_part   = "unit_#{@work_unit_id}"
      
      @local_storage_path ||= File.join(base, action_part, job_part, unit_part)
    end
    
    
    private
    
    # Pilfered from the ActiveSupport::Inflector.
    def underscore(word)
      word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
    
  end
  
end