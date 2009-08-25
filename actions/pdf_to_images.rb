# Depends on working pdftk and gm (GraphicsMagick) commands.
class PdfToImages < CloudCrowd::Action
  
  # Split up a large pdf into single-page pdfs.
  def split
    `pdftk #{input_path} burst output #{work_directory}/#{file_name}_%04d.pdf`
    FileUtils.rm input_path
    Dir["#{work_directory}/*.pdf"].map {|pdf_page| save(pdf_page) }.to_json
  end

  # Convert a pdf page into three different-sized thumbnails.
  def process
    full          = "#{work_directory}/#{file_name}_full.gif"
    thumb         = "#{work_directory}/#{file_name}_thumb.gif"
    icon          = "#{work_directory}/#{file_name}_icon.gif"
    
    cmds = [
      "gm convert -resize 667x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03 #{input_path} #{full}",
      "gm convert -resize 70x #{full} #{thumb}",
      "gm convert -resize 23x #{thumb} #{icon}"
    ]
    system cmds.join(' && ')
    
    { 'full'  => save(full),
      'thumb' => save(thumb),
      'icon'  => save(icon) }.to_json
  end
  
  # Merge all of the resulting images into a single tar archive, ready to
  # use in the DocumentViewer.
  def merge
    inputs = JSON.parse(input).map {|i| JSON.parse(i) }
    inputs.each {|i| i.each {|k, v| i[k] = download(v, "#{work_directory}/#{File.basename(v)}") }}
    FileUtils.mkdir(["#{work_directory}/thumbs", "#{work_directory}/icons"])
    starting_dir = File.expand_path(Dir.pwd)
    tar_path = "#{work_directory}/output.tar"
    
    inputs.each do |input|
      FileUtils.mv(input['full'], input['full'].sub(/_full\.gif\Z/, '.gif'))
      FileUtils.mv(input['thumb'], "#{work_directory}/thumbs/#{File.basename(input['thumb'].sub(/_thumb\.gif\Z/, '.gif'))}")
      FileUtils.mv(input['icon'], "#{work_directory}/icons/#{File.basename(input['icon'].sub(/_icon\.gif\Z/, '.gif'))}")
    end
    
    Dir.chdir work_directory
    `tar -czf #{tar_path} *.gif thumbs icons`
    Dir.chdir starting_dir
    save(tar_path)
  end

end
