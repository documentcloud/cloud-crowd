require 'cloud_crowd/helpers/authorization'
require 'cloud_crowd/helpers/resources'
require 'cloud_crowd/helpers/urls'

module CloudCrowd
  module Helpers
    include Authorization, Resources, Urls #, Rack::Utils
  end
end