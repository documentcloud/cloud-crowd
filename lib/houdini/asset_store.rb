module Houdini

  # The Houdini::AssetStore should provide a common API for stashing and retrieving
  # assets via URLs, in production this will be S3 but in development it may
  # be the filesystem or /tmp.
  class AssetStore
    include FileUtils
    
    def initialize
      mkdir_p(local_storage_path) unless File.exists?(local_storage_path)
    end
    
    def get(job_id, input)
      
    end
    
    def put(job_id, input)
      
    end
    
    def path(job_id, input)
      
    end
    
    def delete(job_id, input)
      
    end
    
    
    private 
    
    def local_storage_path
      "#{Dir.tmpdir}/houdini_assets"
    end
  
  end

end