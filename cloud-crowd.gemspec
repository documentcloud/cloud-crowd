Gem::Specification.new do |s|
  s.name      = 'cloud-crowd'
  s.version   = '0.0.1'
  s.date      = '2009-08-23'

  s.homepage    = "http://documentcloud.org" # wiki page on github?  
  s.summary     = "MapReduce your files in style and comfort."
  s.description = <<-EOS
    The crowd, suddenly there where there was nothing before, is a mysterious and
    universal phenomenon. A few people may have been standing together -- five, ten
    or twelve, nor more; nothing has been announced, nothing is expected. Suddenly
    everywhere is black with people and more come streaming from all sides as though
    streets had only one direction.
  EOS
  
  s.authors     = ['Jeremy Ashkenas']
  s.email       = 'jeremy@documentcloud.org'
  
  s.require_paths = ['lib']
  s.executables   = ['crowd']
  
  s.post_install_message = "Run `crowd help` for information on using CloudCrowd."
  s.rubyforge_project    = 'cloud-crowd'
  s.has_rdoc             = true
  
  s.add_dependency 'sinatra',       ['>= 0.9.4']
  s.add_dependency 'activerecord',  ['>= 2.3.3']
  s.add_dependency 'json',          ['>= 1.1.7']
  s.add_dependency 'rest-client',   ['>= 1.0.3']
  s.add_dependency 'right_aws',     ['>= 1.10.0']
  s.add_dependency 'daemons',       ['>= 1.0.10']

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'faker',               ['>= 0.3.1']
    s.add_development_dependency 'thoughtbot-shoulda',  ['>= 2.10.2']
    s.add_development_dependency 'notahat-machinist',   ['>= 1.0.3']
    s.add_development_dependency 'rack-test',           ['>= 0.4.1']
    s.add_development_dependency 'mocha',               ['>= 0.9.7']
  end
  
  s.files = Dir['./**/*.*']
end