lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_crowd/version'

Gem::Specification.new do |s|
  s.name      = 'cloud-crowd'
  s.version   = CloudCrowd::VERSION
  s.date      = CloudCrowd::VERSION_RELEASED

  s.homepage    = "http://wiki.github.com/documentcloud/cloud-crowd"
  s.summary     = "Parallel Processing for the Rest of Us"
  s.description = <<-EOS
    The crowd, suddenly there where there was nothing before, is a mysterious and
    universal phenomenon. A few people may have been standing together -- five, ten
    or twelve, nor more; nothing has been announced, nothing is expected. Suddenly
    everywhere is black with people and more come streaming from all sides as though
    streets had only one direction.
  EOS
  
  s.license = "MIT"

  s.authors           = ['Jeremy Ashkenas', 'Ted Han', 'Nathan Stitt']
  s.email             = 'opensource@documentcloud.org'
  s.rubyforge_project = 'cloud-crowd'

  s.require_paths     = ['lib']
  s.executables       = ['crowd']

  s.extra_rdoc_files  = ['README']
  s.rdoc_options      << '--title'    << 'CloudCrowd | Parallel Processing for the Rest of Us' <<
                         '--exclude'  << 'test' <<
                         '--main'     << 'README' <<
                         '--all'

  s.add_dependency 'activerecord', '>=3.0'
  s.add_dependency 'sinatra'
  s.add_dependency 'active_model_serializers'
  s.add_dependency 'json',          ['>= 1.1.7']
  s.add_dependency 'rest-client',   ['>= 1.4']
  s.add_dependency 'thin',          ['>= 1.2.4']
  s.add_dependency 'rake'

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'faker',              ['>= 0.3.1']
    s.add_development_dependency 'shoulda'
    s.add_development_dependency 'machinist',          ['>= 1.0.3']
    s.add_development_dependency 'rack-test',          ['>= 0.4.1']
    s.add_development_dependency 'mocha',              ['>= 0.9.7']
  end
  
  s.files = Dir[
    'actions/**/*.rb',
    'cloud-crowd.gemspec',
    'config/**/*.example.*',
    'EPIGRAPHS',
    'examples/**/*.rb',
    'lib/**/*.rb', 
    'LICENSE',
    'public/**/*.{js,css,ico,png,gif}',
    'README',
    'test/**/*.{rb,ru,yml}',
    'views/**/*.erb'
  ]



end
