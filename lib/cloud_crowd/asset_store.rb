require 'tmpdir'

module CloudCrowd

  # The AssetStore provides a common API for storing files and returning URLs 
  # that can access them. In production this will be S3 but in development 
  # it may be the filesystem.
  #
  # You shouldn't need to use the AssetStore directly -- Action's +download+
  # and +save+ methods use it behind the scenes.
  class AssetStore
    
    LOCAL_STORAGE_PATH = '/tmp/cloud_crowd_storage'
    
    # Creating an AssetStore mixes in the specific storage implementation 
    # specified by 'storage' in <tt>config.yml</tt>.
    def initialize
      @use_auth = CloudCrowd.config[:use_s3_authentication]
      @storage  = CloudCrowd.config[:storage]
      FileUtils.mkdir_p temp_storage_path unless File.exists? temp_storage_path
      case @storage
      when 's3'         then extend S3Store
      when 'filesystem' then extend FilesystemStore
      else raise StorageNotFound, "#{@storage} is not a valid storage back end"
      end
    end
    
    # Get the path to CloudCrowd's temporary local storage. All actions run
    # in subdirectories of this.
    def temp_storage_path
      "#{Dir.tmpdir}/cloud_crowd_tmp"
    end
    
    
    # The S3Store is an implementation of an AssetStore that uses a bucket
    # on S3 for all resulting files.
    module S3Store
      
      # Save a finished file from local storage to S3. Save it publicly unless 
      # we're configured to use S3 authentication.
      def save(local_path, save_path)
        ensure_s3_connection
        permission = @use_auth ? 'private' : 'public-read'
        @bucket.put(save_path, File.open(local_path), {}, permission)
      end
      
      # Return the S3 public URL for a finshed file. Authenticated links expire
      # after one day by default.
      def url(save_path)
        @use_auth ? @s3.interface.get_link(@bucket, save_path) :
                    @bucket.key(save_path).public_link
      end
      
      # Remove all of a Job's resulting files from S3, both intermediate and finished.
      def cleanup_job(job)
        ensure_s3_connection
        @bucket.delete_folder("#{job.action}/job_#{job.id}")
      end
      
      # Workers, through the course of many WorkUnits, keep around an AssetStore.
      # Ensure we have a persistent S3 connection after first use.
      def ensure_s3_connection
        unless @s3 && @bucket
          params = {:port => 80, :protocol => 'http'}
          @s3 = RightAws::S3.new(CloudCrowd.config[:aws_access_key], CloudCrowd.config[:aws_secret_key], params)
          @bucket = @s3.bucket(CloudCrowd.config[:s3_bucket], true)
        end
      end
    end
    
    
    # The FilesystemStore is an implementation of the AssetStore, good only for
    # use in development, testing, or if you're only running a single-machine
    # installation.
    module FilesystemStore
      
      # Save a file to somewhere semi-persistent on the filesystem. Can be used
      # in development, when offline, or if you happen to have a single-machine
      # CloudCrowd installation. To use, configure :local_storage.
      def save(local_path, save_path)
        save_path = File.join(LOCAL_STORAGE_PATH, save_path)
        save_dir = File.dirname(save_path)
        FileUtils.mkdir_p save_dir unless File.exists? save_dir
        FileUtils.cp(local_path, save_path)
      end
      
      # Return the URL for a file saved to the local filesystem.
      def url(save_path)
        "file://#{File.expand_path(File.join(LOCAL_STORAGE_PATH, save_path))}"
      end
      
      # Remove all of a Job's result files from the filesystem.
      def cleanup_job(job)
        path = "#{LOCAL_STORAGE_PATH}/#{job.action}/job_#{job.id}"
        FileUtils.rm_r(path) if File.exists?(path)
      end
    end
  
  end

end