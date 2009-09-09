module CloudCrowd
  
  # As you write your custom actions, have them inherit from CloudCrowd::Action.
  # All actions must implement a +process+ method, which should return a 
  # JSON-serializeable object that will be used as the output for the work unit.
  # See the default actions for examples.
  #
  # Optionally, actions may define +split+ and +merge+ methods to do mapping
  # and reducing around the +input+. +split+ should return an array of URLs --
  # to be mapped into WorkUnits and processed in parallel. In the +merge+ step,
  # +input+ will be an array of all the resulting outputs from calling process.
  #
  # All actions have use of an individual +work_directory+, for scratch files,
  # and spend their duration inside of it, so relative paths work well.
  class Action
    
    attr_reader :input, :input_path, :file_name, :options, :work_directory
    
    # Initializing an Action sets up all of the read-only variables that
    # form the bulk of the API for action subclasses. (Paths to read from and
    # write to). It creates the +work_directory+ and moves into it.
    # If we're not merging multiple results, it downloads the input file into
    # the +work_directory+ before starting.
    def initialize(status, input, options, store)
      @input, @options, @store = input, options, store
      @job_id, @work_unit_id = options['job_id'], options['work_unit_id']
      @work_directory = File.expand_path(File.join(@store.temp_storage_path, storage_prefix))
      FileUtils.mkdir_p(@work_directory) unless File.exists?(@work_directory)
      Dir.chdir @work_directory
      if status == MERGING
        @input = JSON.parse(@input)
      else
        @input_path = File.join(@work_directory, safe_filename(@input))
        @file_name = File.basename(@input_path, File.extname(@input_path))
        download(@input, @input_path)
      end
    end
    
    # Each Action subclass must implement a +process+ method, overriding this.
    def process
      raise NotImplementedError.new("CloudCrowd::Actions must override 'process' with their own processing code.")
    end
    
    # Download a file to the specified path.
    def download(url, path)
      resp = RestClient::Request.execute(:url => url, :method => :get, :raw_response => true)
      FileUtils.mv req.file.path, path
      path
    end
    
    # Takes a local filesystem path, saves the file to S3, and returns the 
    # public (or authenticated) url on S3 where the file can be accessed. 
    def save(file_path)
      save_path = File.join(storage_prefix, File.basename(file_path))
      @store.save(file_path, save_path)
      return @store.url(save_path)
    end
    
    # After the Action has finished, we remove the work directory and return
    # to the root directory (where daemons run by default).
    def cleanup_work_directory
      Dir.chdir '/'
      FileUtils.rm_r(@work_directory) if File.exists?(@work_directory)
    end
    
    
    private
    
    # Convert an unsafe URL into a filesystem-friendly filename.
    def safe_filename(url)
      ext = File.extname(url)
      name = File.basename(url).gsub(/%\d+/, '-').gsub(/[^a-zA-Z0-9_\-.]/, '')
      File.basename(name, ext).gsub('.', '-') + ext
    end
    
    # The directory prefix to use for both local and S3 storage.
    # [action_name]/job_[job_id]/unit_[work_unit_it]
    def storage_prefix
      path_parts = []
      path_parts << Inflector.underscore(self.class)
      path_parts << "job_#{@job_id}"
      path_parts << "unit_#{@work_unit_id}" if @work_unit_id
      @storage_prefix ||= File.join(path_parts)
    end
    
  end
  
end