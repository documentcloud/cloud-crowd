gem 'cloudfiles'

module CloudCrowd
  class AssetStore

    # The CloudFilesStore is an implementation of an AssetStore that uses a Rackspace Cloud
    module CloudfilesStore

      # Configure Rackspace Cloud and connect
      def setup
        username  = CloudCrowd.config[:cloudfiles_username]
        api_key   = CloudCrowd.config[:cloudfiles_api_key]
        container = CloudCrowd.config[:cloudfiles_container]
        valid_conf  = [username, api_key, container].all? {|s| s.is_a? String }
        raise Error::MissingConfiguration, "A Rackspace Cloud Files account must be configured in 'config.yml' before 'cloudfiles' storage can be used" unless valid_conf

        @cloud = CloudFiles::Connection.new(username, api_key)
        @container = @cloud.container container
      end

      # Save a finished file from local storage to Cloud Files.
      def save(local_path, save_path)
        object = @container.create_object save_path, true
        object.load_from_filename local_path
        object.public_url
      end

      # Remove all of a Job's resulting files from Cloud Files, both intermediate and finished.
      def cleanup(job)
        @container.objects(:prefix => "#{job.action}/job_#{job.id}").each do |object|
          begin
            @container.delete_object object
          rescue
            log "failed to delete #{job.action}/job_#{job.id}"
          end
        end
      end
    end

  end
end