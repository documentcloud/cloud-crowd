require 'tmpdir'

module CloudCrowd

  # The AssetStore provides a common API for storing files and returning URLs
  # that can access them. At the moment, the files can be saved to either S3, or
  # the local filesystem. You shouldn't need to use the AssetStore directly --
  # Action's +download+ and +save+ methods use it behind the scenes.
  #
  # To implement a new back-end for the AssetStore, you must provide
  # <tt>save(local_path, save_path)</tt>, <tt>cleanup(job)</tt>, and optionally,
  # a <tt>setup</tt> method that will be called once at initialization.
  class AssetStore

    autoload :S3Store,         'cloud_crowd/asset_store/s3_store'
    autoload :FilesystemStore, 'cloud_crowd/asset_store/filesystem_store'
    autoload :CloudfilesStore, 'cloud_crowd/asset_store/cloudfiles_store'

    # Configure the AssetStore with the specific storage implementation
    # specified by 'storage' in <tt>config.yml</tt>.
    case CloudCrowd.config[:storage]
    when 'filesystem' then include FilesystemStore
    when 's3'         then include S3Store
    when 'cloudfiles' then include CloudfilesStore
    else raise Error::StorageNotFound, "#{CloudCrowd.config[:storage]} is not a valid storage back end"
    end

    # Creating the AssetStore ensures that its scratch directory exists.
    def initialize
      FileUtils.mkdir_p temp_storage_path unless File.exists? temp_storage_path
      raise Error::StorageNotWritable, "#{temp_storage_path} is not writable" unless File.writable?(temp_storage_path)
      setup if respond_to? :setup
    end

    # Get the path to CloudCrowd's temporary local storage. All actions run
    # in subdirectories of this.
    def temp_storage_path
      @temp_storage_path ||= CloudCrowd.config[:temp_storage_path] ||  "#{Dir.tmpdir}/cloud_crowd_tmp"
    end

  end

end