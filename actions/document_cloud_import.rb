class DocumentCloudImport < Dogpile::Action
  
  def run
    text_path = extract_full_text
    thumb_path, small_thumb_path = *generate_thumbnails
    fetch_rdf_from_calais
  end
  
  def extract_full_text
    text = DC::Import::TextExtractor.new(input_path).get_text
    path = "#{work_directory}/#{file_name}.txt"
    File.open(path, 'w+') {|f| f.write(text) }
    path
  end
  
  def generate_thumbnails
    image_ex = DC::Import::ThumbnailGenerator.new(input_path)
    image_ex.get_thumbnails
    return [image_ex.thumbnail_path, image_ex.small_thumbnail_path]
  end
  
  def fetch_rdf_from_calais
    
  end
  
end