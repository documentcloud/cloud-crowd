CloudCrowd::Job.blueprint do
  status  { CloudCrowd::PROCESSING }
  inputs  { ['http://www.google.com/intl/en_ALL/images/logo.gif'].to_json }
  action  { 'graphics_magick' }
  options { {}.to_json }
  email   { 'noone@example.com' }
end

CloudCrowd::NodeRecord.blueprint do
  host            { "hostname-#{sn}" }
  ip_address      { '127.0.0.1' }
  port            { 6093 }
  enabled_actions { 'graphics_magick,word_count' }
  max_workers     { 3 }
end

CloudCrowd::WorkUnit.blueprint do
  job     { CloudCrowd::Job.make! }
  status  { CloudCrowd::PROCESSING }
  input   { '{"key":"value"}' }
  action  { 'graphics_magick' }
end