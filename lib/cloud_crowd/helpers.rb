require 'cloud_crowd/helpers/resources'
require 'cloud_crowd/helpers/urls'

module CloudCrowd
  module Helpers
    include Resources, Urls #, Rack::Utils
  end
end