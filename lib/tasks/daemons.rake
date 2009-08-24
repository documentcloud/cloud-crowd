RUNNER_PATH = "#{File.dirname(__FILE__)}/../daemons/runner.rb"
CloudCrowd::App.environment = 'development'

namespace :daemons do
  
  desc 'Start up a pack of worker daemons'
  task :start do
    require 'yaml'
    conf = YAML.load_file("#{File.dirname(__FILE__)}/../../config/cloud_crowd.yml")
    env = defined?(CloudCrowd::App.environment) ? CloudCrowd::App.environment : 'development'
    conf[env]['num_workers'].times do
      `ruby #{RUNNER_PATH} start`
    end
  end
  
  desc 'Stop a running pack of worker daemons'
  task :stop do
    `ruby #{RUNNER_PATH} stop`
  end
  
  desc 'Restart the entire pack of worker daemons'
  task :restart => [:stop, :start]
  
  desc 'Run a single worker in the current process'
  task :run do
    exec "ruby #{RUNNER_PATH} run"
  end
  
  desc 'Check the status of the worker daemons'
  task :status do
    puts `ruby #{RUNNER_PATH} status`
  end
  
end