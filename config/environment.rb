# Be sure to restart your server when you modify this file

# Let's stop matching against +RAILS_ENV+, shall we?
# Make a series of methods like +Rails.production?+
unless defined?(Rails)
  module Rails; end
end
%w(development test staging production).each do |env|
  Rails.module_eval "def self.#{env}?; RAILS_ENV == '#{env}'; end"
end

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  
  # Standard Library:
  require 'tmpdir'
  
  # Gems:
  config.gem 'json', :version => '>= 1.1.7'
  config.gem 'rest-client', :version => '>= 1.0.3', :lib => 'rest_client'
  config.gem 'right_aws', :version => '>= 1.10.0'
  config.gem 'sqlite3-ruby', :version => '>= 1.2.5'
  config.gem 'daemons', :version => '>= 1.0.10'
  
  if Rails.test?
    config.gem 'faker', :version => '>= 0.3.1'
    config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
    config.gem 'notahat-machinist', :lib => 'machinist', :source => 'http://gems.github.com'
  end

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  config.frameworks -= [ :active_resource ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

ActiveSupport::JSON.backend = 'JSONGem'