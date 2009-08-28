module CloudCrowd
  
  # Base CloudCrowd::Action class. Override this with your custom action steps.
  #
  # Public API to CloudCrowd::Action subclasses:
  # +input+, +input_path+, +file_name+, +work_directory+, +options+, +save+
  #
  # CloudCrowd::Actions must implement a +process+ method, which must return a 
  # JSON-serializeable object that will be used as the output for the work unit.
  # Optionally, actions may define +split+ and +merge+ methods to do mapping
  # and reducing around the input.
  # +split+ must return an array of inputs.
  # +merge+ must return the output for the job.
  # All actions run inside of their individual +work_directory+.
  class Action
    
    attr_reader :input, :input_path, :file_name, :options, :work_directory
    
    # Configuring a new Action sets up all of the read-only variables that
    # form the bulk of the API for action subclasses. (Paths to read from and
    # write to).
    def configure(status, input, options, store)
      @input, @options, @store = input, options, store
      @job_id, @work_unit_id = options['job_id'], options['work_unit_id']
      @work_directory = File.expand_path(File.join(@store.temp_storage_path, storage_prefix))
      FileUtils.mkdir_p(@work_directory) unless File.exists?(@work_directory)
      Dir.chdir @work_directory
      unless status == CloudCrowd::MERGING
        @input_path = File.join(@work_directory, File.basename(@input))
        @file_name = File.basename(@input_path, File.extname(@input_path))
        download(@input, @input_path)
      end
    end
    
    # Each CloudCrowd::Action must implement a +process+ method.
    def process
      raise NotImplementedError.new("CloudCrowd::Actions must override 'process' with their own processing code.")
    end
    
    # Download a file to the specified path using curl.
    def download(url, path)
      `curl -s "#{url}" > #{path}`
      path
    end
    
    # Takes a local filesystem path, and returns the public (or authenticated) 
    # url on S3 where the file was saved. 
    def save(file_path)
      save_path = File.join(s3_storage_path, File.basename(file_path))
      @store.save(file_path, save_path)
      return @store.url(save_path)
    end
    
    # After the Action has finished, we remove the work directory and return
    # to the root directory (where daemons run by default).
    def cleanup_work_directory
      Dir.chdir '/'
      FileUtils.rm_r(@work_directory)
    end
    
    
    private
    
    # The directory prefix to use for both local and S3 storage.
    # [action_name]/job_[job_id]/unit_[work_unit_it]
    def storage_prefix
      path_parts = []
      path_parts << Inflector.underscore(self.class)
      path_parts << "job_#{@job_id}"
      path_parts << "unit_#{@work_unit_id}" if @work_unit_id
      @storage_prefix ||= File.join(path_parts)
    end
    
    def s3_storage_path
      @s3_storage_path ||= storage_prefix
    end
    
  end
  
end