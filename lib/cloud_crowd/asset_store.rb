require 'tmpdir'

module CloudCrowd

  # The AssetStore provides a common API for storing files and returning URLs 
  # that can access them. In production this will be S3 but in development 
  # it may be the filesystem.
  #
  # You shouldn't need to use the AssetStore directly -- Action's +download+
  # and +save+ methods use it behind the scenes.
  class AssetStore
    
    autoload :S3Store,         'cloud_crowd/asset_store/s3_store'
    autoload :FilesystemStore, 'cloud_crowd/asset_store/filesystem_store'
    
    LOCAL_STORAGE_PATH = '/tmp/cloud_crowd_storage'
    
    # Configure the AssetStore with the specific storage implementation 
    # specified by 'storage' in <tt>config.yml</tt>.
    case CloudCrowd.config[:storage]
    when 's3'         then include S3Store
    when 'filesystem' then include FilesystemStore
    else raise StorageNotFound, "#{CloudCrowd.config[:storage]} is not a valid storage back end"
    end
    
    # Creating the AssetStore ensures that its scratch directory exists.
    def initialize
      @use_auth = CloudCrowd.config[:use_s3_authentication]
      FileUtils.mkdir_p temp_storage_path unless File.exists? temp_storage_path
      raise StorageNotWritable, "#{temp_storage_path} is not writable" unless File.writable?(temp_storage_path)
    end
    
    # Get the path to CloudCrowd's temporary local storage. All actions run
    # in subdirectories of this.
    def temp_storage_path
      "#{Dir.tmpdir}/cloud_crowd_tmp"
    end
  
  end

end