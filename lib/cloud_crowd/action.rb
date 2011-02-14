module CloudCrowd

  # As you write your custom actions, have them inherit from CloudCrowd::Action.
  # All actions must implement a +process+ method, which should return a
  # JSON-serializable object that will be used as the output for the work unit.
  # See the default actions for examples.
  #
  # Optionally, actions may define +split+ and +merge+ methods to do mapping
  # and reducing around the +input+. +split+ should return an array of URLs --
  # to be mapped into WorkUnits and processed in parallel. In the +merge+ step,
  # +input+ will be an array of all the resulting outputs from calling process.
  #
  # All actions have use of an individual +work_directory+, for scratch files,
  # and spend their duration inside of it, so relative paths work well.
  #
  # Note that Actions inherit a backticks (`) method that raises an Exception
  # if the external command fails.
  class Action

    FILE_URL = /\Afile:\/\//

    attr_reader :input, :input_path, :file_name, :options, :work_directory

    # Initializing an Action sets up all of the read-only variables that
    # form the bulk of the API for action subclasses. (Paths to read from and
    # write to). It creates the +work_directory+ and moves into it.
    # If we're not merging multiple results, it downloads the input file into
    # the +work_directory+ before starting.
    def initialize(status, input, options, store)
      @input, @options, @store = input, options, store
      @job_id, @work_unit_id = options['job_id'], options['work_unit_id']
      @work_directory = File.expand_path(File.join(@store.temp_storage_path, local_storage_prefix))
      FileUtils.mkdir_p(@work_directory) unless File.exists?(@work_directory)
      parse_input
      download_input
    end

    # Each Action subclass must implement a +process+ method, overriding this.
    def process
      raise NotImplementedError, "CloudCrowd::Actions must override 'process' with their own processing code."
    end

    # Download a file to the specified path.
    def download(url, path)
      if url.match(FILE_URL)
        FileUtils.cp(url.sub(FILE_URL, ''), path)
      else
        File.open(path, 'w+') do |file|
          Net::HTTP.get_response(URI(url)) do |response|
            response.read_body do |chunk|
              file.write chunk
            end
          end
        end
      end
      path
    end

    # Takes a local filesystem path, saves the file to S3, and returns the
    # public (or authenticated) url on S3 where the file can be accessed.
    def save(file_path)
      save_path = File.join(remote_storage_prefix, File.basename(file_path))
      @store.save(file_path, save_path)
    end

    # After the Action has finished, we remove the work directory and return
    # to the root directory (where workers run by default).
    def cleanup_work_directory
      FileUtils.rm_r(@work_directory) if File.exists?(@work_directory)
    end

    # Actions have a backticks command that raises a CommandFailed exception
    # on failure, so that processing doesn't just blithely continue.
    def `(command)
      result    = super(command)
      exit_code = $?.to_i
      raise Error::CommandFailed.new(result, exit_code) unless exit_code == 0
      result
    end


    private

    # Convert an unsafe URL into a filesystem-friendly filename.
    def safe_filename(url)
      url  = url.sub(/\?.*\Z/, '')
      ext  = File.extname(url)
      name = URI.unescape(File.basename(url)).gsub(/[^a-zA-Z0-9_\-.]/, '-').gsub(/-+/, '-')
      File.basename(name, ext).gsub('.', '-') + ext
    end

    # The directory prefix to use for remote storage.
    # [action]/job_[job_id]
    def remote_storage_prefix
      @remote_storage_prefix ||= Inflector.underscore(self.class) +
        "/job_#{@job_id}" + (@work_unit_id ? "/unit_#{@work_unit_id}" : '')
    end

    # The directory prefix to use for local storage.
    # [action]/unit_[work_unit_id]
    def local_storage_prefix
      @local_storage_prefix ||= Inflector.underscore(self.class) +
        (@work_unit_id ? "/unit_#{@work_unit_id}" : '')
    end

    # If we think that the input is JSON, replace it with the parsed form.
    # It would be great if the JSON module had an is_json? method.
    def parse_input
      return unless ['[', '{'].include? @input[0..0]
      @input = JSON.parse(@input) rescue @input
    end

    def input_is_url?
      !URI.parse(@input).scheme.nil? rescue false
    end

    # If the input is a URL, download the file before beginning processing.
    def download_input
      return unless input_is_url?
      Dir.chdir(@work_directory) do
        @input_path = File.join(@work_directory, safe_filename(@input))
        @file_name = File.basename(@input_path, File.extname(@input_path))
        download(@input, @input_path)
      end
    end

  end

end