require 'test_helper'

class CommandLineTest < Test::Unit::TestCase
  
  context "A CloudCrowd::CommandLine" do
    
    should "install into the directory that you ask it to" do
      dir = 'tmp/install_dir'
      ARGV.replace ['install', dir]
      CloudCrowd::CommandLine.new
      assert File.exists?(dir)
      assert File.directory?(dir)
      CloudCrowd::CommandLine::CONFIG_FILES.each do |file|
        assert File.exists?("#{dir}/#{file}")
      end
      FileUtils.rm_r(dir)
    end
    
  end
  
end
