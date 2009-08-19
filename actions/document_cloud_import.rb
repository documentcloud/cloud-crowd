require "#{RAILS_ROOT}/lib/dc/import/calais_fetcher"
require "#{RAILS_ROOT}/lib/dc/import/image_extractor"
require "#{RAILS_ROOT}/lib/dc/import/text_extractor"

class DocumentCloudImport < Dogpile::Action
  
  def run
    text_path, title = extract_full_text_and_title
    thumb_path, small_thumb_path = *generate_thumbnails
    rdf_path = fetch_rdf_from_calais
    {
      'title'               => title,
      'full_text_url'       => save(text_path),
      'rdf_url'             => save(rdf_path),
      'thumbnail_url'       => save(thumb_path),
      'small_thumbnail_url' => save(small_thumb_path)
    }
  end
  
  def extract_full_text_and_title
    ex = DC::Import::TextExtractor.new(input_path)
    @text = ex.get_text
    # TODO: Replace with a better exception.
    raise "hell" if @text.length > DC::Import::CalaisFetcher::MAX_TEXT_SIZE
    path = "#{work_directory}/#{file_name}.txt"
    File.open(path, 'w+') {|f| f.write(@text) }
    [path, ex.get_title || "Untitled Document"]
  end
  
  def generate_thumbnails
    image_ex = DC::Import::ImageExtractor.new(input_path)
    image_ex.get_thumbnails
    [image_ex.thumbnail_path, image_ex.small_thumbnail_path]
  end
  
  def fetch_rdf_from_calais
    path = "#{work_directory}/#{file_name}.rdf"
    rdf = DC::Import::CalaisFetcher.new.fetch_rdf(@text)
    File.open(path, 'w+') {|f| f.write(rdf) }
    path
  end
  
end