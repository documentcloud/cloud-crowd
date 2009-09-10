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
    
    # Creating an AssetStore will determine wether to save private or public
    # files on S3, depending on the value of <tt>use_s3_authentication</tt> in 
    # <tt>config.yml</tt>.
    def initialize
      @use_auth = CloudCrowd.config[:use_s3_authentication]
      @use_s3   = !CloudCrowd.config[:use_local_storage]
      FileUtils.mkdir_p temp_storage_path unless File.exists? temp_storage_path
    end
    
    # Get the path to CloudCrowd's temporary local storage. All actions run
    # in subdirectories of this.
    def temp_storage_path
      "#{Dir.tmpdir}/cloud_crowd_tmp"
    end
    
    # Save a finished file.
    def save(*args)
      @use_s3 ? save_to_s3(*args) : save_to_filesystem(*args)
    end
    
    # Cleanup all files for a job that's been completed and retrieved.
    def cleanup_job(job)
      @use_s3 ? clean_up_s3(job) : clean_up_filesystem(job)
    end
    
    # Return the URL that can be used to retrieve a saved file.
    def url(save_path)
      @use_s3 ? s3_url(save_path) : filesystem_url(save_path)
    end
    
    private
    
    # Save a file to somewhere semi-persistent on the filesystem. Can be used
    # in development, when offline, or if you happen to have a single-machine
    # CloudCrowd installation. To use, configure :local_storage.
    def save_to_filesystem(local_path, save_path)
      save_path = File.join(LOCAL_STORAGE_PATH, save_path)
      save_dir = File.dirname(save_path)
      FileUtils.mkdir_p save_dir unless File.exists? save_dir
      FileUtils.cp(local_path, save_path)
    end
    
    # Save a finished file from local storage to S3. Save it publicly unless 
    # we're configured to use S3 authentication.
    def save_to_s3(local_path, save_path)
      ensure_s3_connection
      permission = @use_auth ? 'private' : 'public-read'
      @bucket.put(save_path, File.open(local_path), {}, permission)
    end
    
    # Return the URL for a file saved to the local filesystem.
    def filesystem_url(save_path)
      "file://#{File.expand_path(File.join(LOCAL_STORAGE_PATH, save_path))}"
    end
    
    # Return the S3 public URL for a finshed file. Authenticated links expire
    # after one day by default.
    def s3_url(save_path)
      @use_auth ? @s3.interface.get_link(@bucket, save_path) :
                  @bucket.key(save_path).public_link
    end
    
    def clean_up_filesystem(job)
      path = "#{LOCAL_STORAGE_PATH}/#{job.action}/job_#{job.id}"
      FileUtils.rm_r(path) if File.exists?(path)
    end
    
    def clean_up_s3(job)
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

end