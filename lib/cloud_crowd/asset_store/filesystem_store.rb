module CloudCrowd
  class AssetStore
    
    # The FilesystemStore is an implementation of the AssetStore, good only for
    # use in development, testing, or if you're only running a single-machine
    # installation.
    module FilesystemStore
      
      # Make sure that local storage is writeable before starting.
      def setup
        raise Error::StorageNotWritable, "#{LOCAL_STORAGE_PATH} is not writable" unless File.writable?(LOCAL_STORAGE_PATH)
      end
      
      # Save a file to somewhere semi-persistent on the filesystem. Can be used
      # in development, when offline, or if you happen to have a single-machine
      # CloudCrowd installation. To use, configure <tt>:storage => 'filesystem'</tt>.
      def save(local_path, save_path)
        save_path = File.join(LOCAL_STORAGE_PATH, save_path)
        save_dir = File.dirname(save_path)
        FileUtils.mkdir_p save_dir unless File.exists? save_dir
        FileUtils.cp(local_path, save_path)
        "file://#{File.expand_path(save_path)}"
      end
      
      # Remove all of a Job's result files from the filesystem.
      def cleanup(job)
        path = "#{LOCAL_STORAGE_PATH}/#{job.action}/job_#{job.id}"
        FileUtils.rm_r(path) if File.exists?(path)
      end
    end
    
  end
end