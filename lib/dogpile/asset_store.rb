module Dogpile

  # The Dogpile::AssetStore should provide a common API for stashing and retrieving
  # assets via URLs, in production this will be S3 but in development it may
  # be the filesystem or /tmp.
  class AssetStore
    include FileUtils
    
    def initialize
      mkdir_p temp_storage_path unless File.exists? temp_storage_path
    end
    
    def temp_storage_path
      "#{Dir.tmpdir}/dogpile_tmp"
    end
    
    def save(local_path, save_path)
      # if RAILS_ENV == 'development'
      #   save_to_filesystem(local_path, save_path)
      # else
        save_to_s3(local_path, save_path)
      # end
    end
    
    def url(save_path)
      @bucket.key(save_path).public_link
    end
    
    private
    
    def save_to_filesystem(local_path, save_path)
      save_path = File.join("/tmp/dogpile_storage", save_path)
      save_dir = File.dirname(save_path)
      mkdir_p save_dir unless File.exists? save_dir
      cp(local_path, save_path)
    end
    
    def save_to_s3(local_path, save_path)
      ensure_s3_connection
      @bucket.put(save_path, File.open(local_path), {}, 'public-read')
    end
    
    def ensure_s3_connection
      unless @s3 && @bucket
        params = {:port => 80, :protocol => 'http'}
        @s3 = RightAws::S3.new(Dogpile::SECRETS['aws_access_key'], Dogpile::SECRETS['aws_secret_key'], params)
        @bucket = @s3.bucket(Dogpile::CONFIG['s3_bucket'], true)
      end
    end
  
  end

end