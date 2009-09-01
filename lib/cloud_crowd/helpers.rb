require 'cloud_crowd/helpers/authorization'
require 'cloud_crowd/helpers/resources'

module CloudCrowd
  module Helpers #:nodoc:
    include Authorization, Resources #, Rack::Utils
  end
end