Gem::Specification.new do |s|
  s.name      = 'cloud-crowd'
  s.version   = '0.6.2'         # Keep version in sync with cloud-cloud.rb
  s.date      = '2011-04-14'

  s.homepage    = "http://wiki.github.com/documentcloud/cloud-crowd"
  s.summary     = "Parallel Processing for the Rest of Us"
  s.description = <<-EOS
    The crowd, suddenly there where there was nothing before, is a mysterious and
    universal phenomenon. A few people may have been standing together -- five, ten
    or twelve, nor more; nothing has been announced, nothing is expected. Suddenly
    everywhere is black with people and more come streaming from all sides as though
    streets had only one direction.
  EOS

  s.authors           = ['Jeremy Ashkenas']
  s.email             = 'jeremy@documentcloud.org'
  s.rubyforge_project = 'cloud-crowd'

  s.require_paths     = ['lib']
  s.executables       = ['crowd']

  s.extra_rdoc_files  = ['README']
  s.rdoc_options      << '--title'    << 'CloudCrowd | Parallel Processing for the Rest of Us' <<
                         '--exclude'  << 'test' <<
                         '--main'     << 'README' <<
                         '--all'

  s.add_dependency 'sinatra',       ['~> 1.2.6']
  s.add_dependency 'activerecord',  ['~> 2.3']
  s.add_dependency 'json',          ['>= 1.1.7']
  s.add_dependency 'rest-client',   ['>= 1.4']
  s.add_dependency 'thin',          ['>= 1.2.4']

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'faker',               ['>= 0.3.1']
    s.add_development_dependency 'thoughtbot-shoulda',  ['>= 2.10.2']
    s.add_development_dependency 'notahat-machinist',   ['>= 1.0.3']
    s.add_development_dependency 'rack-test',           ['>= 0.4.1']
    s.add_development_dependency 'mocha',               ['>= 0.9.7']
  end

  s.files = %w(
actions/graphics_magick.rb
actions/process_pdfs.rb
actions/word_count.rb
cloud-crowd.gemspec
config/config.example.ru
config/config.example.yml
config/database.example.yml
EPIGRAPHS
examples/graphics_magick_example.rb
examples/process_pdfs_example.rb
examples/word_count_example.rb
lib/cloud-crowd.rb
lib/cloud_crowd/action.rb
lib/cloud_crowd/asset_store/filesystem_store.rb
lib/cloud_crowd/asset_store/s3_store.rb
lib/cloud_crowd/asset_store/cloudfiles_store.rb
lib/cloud_crowd/asset_store.rb
lib/cloud_crowd/command_line.rb
lib/cloud_crowd/exceptions.rb
lib/cloud_crowd/helpers/authorization.rb
lib/cloud_crowd/helpers/resources.rb
lib/cloud_crowd/helpers.rb
lib/cloud_crowd/inflector.rb
lib/cloud_crowd/models/job.rb
lib/cloud_crowd/models/node_record.rb
lib/cloud_crowd/models/work_unit.rb
lib/cloud_crowd/models.rb
lib/cloud_crowd/node.rb
lib/cloud_crowd/schema.rb
lib/cloud_crowd/server.rb
lib/cloud_crowd/worker.rb
LICENSE
public/css/admin_console.css
public/css/reset.css
public/images/bullet_green.png
public/images/bullet_white.png
public/images/cloud_hand.png
public/images/header_back.png
public/images/logo.png
public/images/queue_fill.png
public/images/server.png
public/images/server_busy.png
public/images/server_error.png
public/images/sidebar_bottom.png
public/images/sidebar_top.png
public/images/worker_info.png
public/images/worker_info_loading.gif
public/js/admin_console.js
public/js/excanvas.js
public/js/flot.js
public/js/jquery.js
README
test/acceptance/test_node.rb
test/acceptance/test_failing_work_units.rb
test/acceptance/test_server.rb
test/acceptance/test_word_count.rb
test/blueprints.rb
test/config/config.ru
test/config/config.yml
test/config/database.yml
test/config/actions/failure_testing.rb
test/test_helper.rb
test/unit/test_action.rb
test/unit/test_configuration.rb
test/unit/test_node.rb
test/unit/test_node_record.rb
test/unit/test_job.rb
test/unit/test_worker.rb
test/unit/test_work_unit.rb
views/operations_center.erb
)
end
