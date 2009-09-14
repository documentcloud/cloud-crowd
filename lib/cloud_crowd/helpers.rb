require 'cloud_crowd/helpers/authorization'
require 'cloud_crowd/helpers/resources'

module CloudCrowd
  module Helpers
    include Authorization, Resources #, Rack::Utils
  end
end