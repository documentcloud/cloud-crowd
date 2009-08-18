module Dogpile

  # The Dogpile::AssetStore should provide a common API for stashing and retrieving
  # assets via URLs, in production this will be S3 but in development it may
  # be the filesystem or /tmp.
  class AssetStore
    include FileUtils
    
    def initialize
      mkdir_p local_storage_path unless exists? local_storage_path
    end
    
    def temp_storage_path
      "#{Dir.tmpdir}/dogpile_tmp"
    end
    
    def save(local_path, save_path)
      if RAILS_ENV == 'development'
        save_to_filesystem(local_path, remote_path)
      else
        save_to_s3(local_path, remote_path)
      end
    end
    
    private
    
    def save_to_filesystem(local_path, save_path)
      save_path = join("/tmp/dogpile_storage", save_path)
      save_dir = dirname(save_path)
      mkdir_p save_dir unless exists? save_dir
      cp(local_path, save_path)
    end
    
    def save_to_s3(local_path, save_path)
      
    end
  
  end

end