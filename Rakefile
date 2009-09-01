require 'rake/testtask'

namespace :gem do
  
  desc 'Build and install cloud-crowd gem'
  task :install do
    sh "gem build cloud-crowd.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --no-ri"
  end
  
  desc 'Uninstall the cloud-crowd gem'
  task :uninstall do
    sh "sudo gem uninstall -x cloud-crowd"
  end
  
end
