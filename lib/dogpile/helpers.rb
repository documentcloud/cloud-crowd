require 'dogpile/helpers/resources'
require 'dogpile/helpers/urls'

module Dogpile
  module Helpers
    include Resources, Urls #, Rack::Utils
  end
end