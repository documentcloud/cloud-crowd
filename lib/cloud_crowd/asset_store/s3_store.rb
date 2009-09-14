module CloudCrowd
  class AssetStore
    
    # The S3Store is an implementation of an AssetStore that uses a bucket
    # on S3 for all resulting files.
    module S3Store
      
      # Save a finished file from local storage to S3. Save it publicly unless 
      # we're configured to use S3 authentication. Authenticated links expire
      # after one day by default.
      def save(local_path, save_path)
        ensure_s3_connection
        if @use_auth
          @bucket.put(save_path, File.open(local_path), {}, 'private')
          @s3.interface.get_link(@bucket, save_path)
        else
          @bucket.put(save_path, File.open(local_path), {}, 'public-read')
          @bucket.key(save_path).public_link
        end
      end
            
      # Remove all of a Job's resulting files from S3, both intermediate and finished.
      def cleanup(job)
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
end