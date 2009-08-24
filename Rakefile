require 'rake/testtask'

namespace :gem do
  
  desc 'Build and install cloud-crowd gem'
  task :install do
    sh "gem build cloud-crowd.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --no-ri --no-rdoc"
  end
  
  desc 'Uninstall the cloud-crowd gem'
  task :uninstall do
    sh "sudo gem uninstall -x cloud-crowd"
  end
  
end

namespace :db do
  
  desc 'Load the database schema'
  task :load_schema do
    sh 'ruby -rubygems -r lib/cloud-crowd lib/cloud_crowd/schema.rb'
  end
  
end
