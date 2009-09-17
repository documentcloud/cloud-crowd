module CloudCrowd
  class AssetStore
    
    # The FilesystemStore is an implementation of the AssetStore, good only for
    # use in development, testing, if you're only running a single-machine
    # installation, or are using a networked drive.
    module FilesystemStore
      
      DEFAULT_STORAGE_PATH = '/tmp/cloud_crowd_storage'
      
      attr_reader :local_storage_path
      
      # Make sure that local storage exists and is writeable before starting.
      def setup
        lsp = @local_storage_path = CloudCrowd.config[:local_storage_path] || DEFAULT_STORAGE_PATH
        FileUtils.mkdir_p(lsp) unless File.exists?(lsp)
        raise Error::StorageNotWritable, "#{lsp} is not writable" unless File.writable?(lsp)
      end
      
      # Save a file to somewhere semi-persistent on the filesystem. To use, 
      # configure <tt>:storage: 'filesystem'</tt> in *config.yml*, as well as
      # <tt>:local_storage_path:</tt>.
      def save(local_path, save_path)
        save_path = File.join(@local_storage_path, save_path)
        save_dir = File.dirname(save_path)
        FileUtils.mkdir_p save_dir unless File.exists? save_dir
        FileUtils.cp(local_path, save_path)
        "file://#{File.expand_path(save_path)}"
      end
      
      # Remove all of a Job's result files from the filesystem.
      def cleanup(job)
        path = "#{@local_storage_path}/#{job.action}/job_#{job.id}"
        FileUtils.rm_r(path) if File.exists?(path)
      end
    end
    
  end
end