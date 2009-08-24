# Use the 'db' settings in cloud_crowd.yml to connect to the database.
ActiveRecord::Base.establish_connection(CloudCrowd::CONFIG[:db])

require 'cloud_crowd/models/job'
require 'cloud_crowd/models/work_unit'