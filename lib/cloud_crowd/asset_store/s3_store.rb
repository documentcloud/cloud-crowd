require 'aws'

module CloudCrowd
  class AssetStore

    # The S3Store is an implementation of an AssetStore that uses a bucket
    # on S3 for all resulting files.
    module S3Store

      # Configure authentication and establish a connection to S3, first thing.
      def setup
        @use_auth   = CloudCrowd.config[:s3_authentication]
        bucket_name = CloudCrowd.config[:s3_bucket]
        key, secret = CloudCrowd.config[:aws_access_key], CloudCrowd.config[:aws_secret_key]
        valid_conf  = [bucket_name, key, secret].all? {|s| s.is_a? String }
        raise Error::MissingConfiguration, "An S3 account must be configured in 'config.yml' before 's3' storage can be used" unless valid_conf
        @s3         = ::AWS::S3.new(:access_key_id => key, :secret_access_key => secret, :secure => !!@use_auth)
        @bucket     = (@s3.buckets[bucket_name].exists? ? @s3.buckets[bucket_name] : @s3.buckets.create(bucket_name))
      end

      # Save a finished file from local storage to S3. Save it publicly unless
      # we're configured to use S3 authentication. Authenticated links expire
      # after one day by default.
      def save(local_path, save_path)
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
        @bucket.delete_folder("#{job.action}/job_#{job.id}")
      end

    end

  end
end