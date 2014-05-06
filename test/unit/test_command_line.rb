require 'test_helper'

class CommandLineTest < Minitest::Test
  
  context "A CloudCrowd::CommandLine" do
    
    should "install into the directory that you ask it to" do
      dir = 'tmp/test_install_dir'
      ARGV.replace ['install', dir]
      CloudCrowd::CommandLine.new
      assert File.exists?(dir)
      assert File.directory?(dir)
      CloudCrowd::CommandLine::CONFIG_FILES.each do |file|
        assert File.exists?("#{dir}/#{file}")
      end
      FileUtils.rm_r(dir)
    end
    
    should "mix in CloudCrowd to the top level of `crowd console` sessions" do
      require 'irb'
      ARGV.replace ['-c', 'test/config', 'console']
      IRB.expects(:start)
      CloudCrowd::CommandLine.new
      ['Job', 'WorkUnit', 'Server', 'Node', 'SUCCEEDED', 'FAILED'].each do |constant|
        assert Object.constants.include?(constant.to_sym), "CommandLine includes #{constant}"
      end
    end
    
  end
  
end
