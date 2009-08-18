Sham.url        { Faker::Internet.domain_name + "/" + Faker::Internet.domain_word + ".jpg" }

Job.blueprint do
  status  { Dogpile::PROCESSING }
  inputs  { ['http://www.google.com/intl/en_ALL/images/logo.gif'].to_json }
  action  { 'graphics_magick' }
  options { {}.to_json }
end

WorkUnit.blueprint do
  job_id { rand(10000) }
  status { Dogpile::PENDING }
  input  { Sham.url }
end