module Dogpile

  # The Dogpile::AssetStore should provide a common API for stashing and retrieving
  # assets via URLs, in production this will be S3 but in development it may
  # be the filesystem or /tmp.
  class AssetStore
    include FileUtils
    
    def initialize
      mkdir_p temp_storage_path unless File.exists? temp_storage_path
    end
    
    # Path to Dogpile's temporary local storage.
    def temp_storage_path
      "#{Dir.tmpdir}/dogpile_tmp"
    end
    
    # Copy a finished file from our local storage to S3.
    def save(local_path, save_path)
      ensure_s3_connection
      @bucket.put(save_path, File.open(local_path), {}, 'public-read')
    end
    
    # Cleanup all S3 files for a job that's been completed and retrieved.
    def cleanup_job(job)
      ensure_s3_connection
      @bucket.delete_folder("#{job.action}/job_#{job.id}")
    end
    
    # Return the S3 public URL for a finshed file.
    def url(save_path)
      @bucket.key(save_path).public_link
    end
    
    private
    
    # Unused for the moment. Think about using the filesystem instead of S3
    # in development.
    def save_to_filesystem(local_path, save_path)
      save_path = File.join("/tmp/dogpile_storage", save_path)
      save_dir = File.dirname(save_path)
      mkdir_p save_dir unless File.exists? save_dir
      cp(local_path, save_path)
    end
    
    # Workers, through the course of many WorkUnits, keep around an AssetStore.
    # Ensure we have a persistent S3 connection after first use.
    def ensure_s3_connection
      unless @s3 && @bucket
        params = {:port => 80, :protocol => 'http'}
        @s3 = RightAws::S3.new(SECRETS['aws_access_key'], SECRETS['aws_secret_key'], params)
        @bucket = @s3.bucket(Dogpile::CONFIG['s3_bucket'], true)
      end
    end
  
  end

end