# This is the script that kicks off a single CloudCrowd::Daemon. Rely on 
# cloud-crowd.rb for autoloading of all the code we need.

require "#{File.dirname(__FILE__)}/../cloud-crowd"

FileUtils.mkdir('log') unless File.exists?('log')

Daemons.run("#{CloudCrowd::ROOT}/lib/cloud_crowd/daemon.rb", {
  :app_name   => "cloud_crowd_worker",
  :dir_mode   => :normal,
  :dir        => 'log',
  :multiple   => true,
  :backtrace  => true,
  :log_output => true
})
