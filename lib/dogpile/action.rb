module Dogpile
  
  # Base Dogpile::Action class. Override this with your custom action steps.
  #
  # Public API to Dogpile::Action subclasses:
  # +input_url+, +input_path+, +file_name+, +work_directory+, +options+, +save+
  #
  # Dogpile::Actions must implement a +run+ method, which must return a 
  # JSON-serializeable object that will be used as the output for the work unit.
  class Action
    
    attr_reader :input_url, :input_path, :file_name, :options, :work_directory
    
    # Initializing a new Action sets up all of the read-only variables that
    # form the bulk of the API for action subclasses. (Paths to read from and
    # write to).
    def initialize(input_url, options, store)
      @input_url, @options, @store = input_url, options, store
      @job_id, @work_unit_id = options['job_id'], options['work_unit_id']
      @work_directory = File.join(@store.temp_storage_path, storage_prefix)
      @input_path = File.join(@work_directory, File.basename(@input_url))
      @file_name = File.basename(@input_path, File.extname(@input_path))
      FileUtils.mkdir_p(@work_directory) unless File.exists?(@work_directory)
      `curl -s "#{@input_url}" > #{@input_path}`
    end
    
    # Each Dogpile::Action must implement a +run+ method.
    def run
      raise NotImplementedError.new("Dogpile::Actions must override 'run' with their own processing code.")
    end
    
    # Takes a local filesystem path, and returns the public url on S3 where the 
    # file was saved. 
    def save(file_path)
      save_path = File.join(s3_storage_path, File.basename(file_path))
      @store.save(file_path, save_path)
      return @store.url(save_path)
    end
    
    # After the Action has finished, we remove the work directory.
    def cleanup_work_directory
      FileUtils.rm_r(@work_directory)
    end
    
    
    private
    
    # The directory prefix to use for both local and S3 storage.
    # [action_name]/job_[job_id]/unit_[work_unit_it]
    def storage_prefix
      action_part = underscore(self.class.to_s)
      job_part    = "job_#{@job_id}"
      unit_part   = "unit_#{@work_unit_id}"
      @storage_prefix ||= File.join(action_part, job_part, unit_part)
    end
    
    def s3_storage_path
      @s3_storage_path ||= storage_prefix
    end
    
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