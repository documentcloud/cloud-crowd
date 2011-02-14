require 'test_helper'

class CloudCrowd::Action
  public :safe_filename
end

class EmptyAction < CloudCrowd::Action
end

class ActionTest < Test::Unit::TestCase

  context "A CloudCrowd::Action" do

    setup do
      @store = CloudCrowd::AssetStore.new
      @args = [CloudCrowd::PROCESSING, 'file://' + File.expand_path(__FILE__), {'job_id' => 1, 'work_unit_id' => 1}, @store]
      @action = CloudCrowd.actions['word_count'].new(*@args)
    end

    should "throw an exception if the 'process' method isn't implemented" do
      assert_raise(NotImplementedError) { EmptyAction.new(*@args).process }
    end

    should "have downloaded the input URL to local storage" do
      assert @action.input_path
      assert File.read(@action.input_path) == File.read(File.expand_path(__FILE__))
    end

    should "be able to save (to the filesystem while testing)" do
      assert @action.save(@action.input_path) == "file://#{@store.local_storage_path}/word_count/job_1/unit_1/test_action.rb"
    end

    should "be able to clean up after itself" do
      @action.cleanup_work_directory
      assert !File.exists?(@action.work_directory)
    end

    should "be able to generate a safe filename for a URL to write to disk" do
      name = @action.safe_filename("http://example.com/Some%20(Crazy'Kinda%7E)'Filename.txt")
      assert name == 'Some-Crazy-Kinda-Filename.txt'
      name = @action.safe_filename("http://example.com/file.pdf?one=two&three=four")
      assert name == 'file.pdf'
    end

    should "not change the original URL when generating a safe filename" do
      url = "http://example.com/file.format?parameter=value"
      path = @action.safe_filename url
      assert url == "http://example.com/file.format?parameter=value"
      assert path == "file.format"
    end

    should "be able to count the number of words in this file" do
      assert @action.process == 266
    end

    should "raise an exception when backticks fail" do
      def @action.process; `utter failure 2>&1`; end
      assert_raise(CloudCrowd::Error::CommandFailed) { @action.process }
    end

    should "be able to download a remote file" do
      path = "temp.txt"
      @action.download('http://www.w3.org', path)
      assert File.read(path).match(/standards/i)
      FileUtils.rm path
    end

  end


  context "A CloudCrowd::Action without URL input" do

    setup do
      @store = CloudCrowd::AssetStore.new
      @args = [CloudCrowd::PROCESSING, 'inputstring', {'job_id' => 1, 'work_unit_id' => 1}, @store]
      @action = CloudCrowd.actions['word_count'].new(*@args)
    end

    should "should not interpret the input data as an url" do
      assert_equal 'inputstring', @action.input
      assert_nil @action.input_path
    end

  end

end
