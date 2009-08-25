# Depends on working pdftk and gm (GraphicsMagick) commands.
# Splits a pdf into batches of N pages, creates their thumbnails and icons,
# and merges all the images back into a tar archive for convenient download.
class PdfToImages < CloudCrowd::Action
  
  # Split up a large pdf into single-page pdfs.
  def split
    `pdftk #{input_path} burst output #{file_name}_%04d.pdf`
    FileUtils.rm input_path
    pdfs = Dir["*.pdf"]
    batch_size = options['batch_size']
    batches = (pdfs.length / batch_size.to_f).ceil
    batches.times do |batch_num|
      tar_path = "#{sprintf('%04d', batch_num)}.tar"
      batch_pdfs = pdfs[batch_num*batch_size...(batch_num + 1)*batch_size]
      `tar -czf #{tar_path} #{batch_pdfs.join(' ')}`
    end
    Dir["*.tar"].map {|tar| save(tar) }.to_json
  end

  # Convert a pdf page into three different-sized thumbnails.
  def process
    `tar -xzf #{input_path}`
    FileUtils.rm input_path
    results = []
    Dir["*.pdf"].each do |pdf| 
      name          = File.basename(pdf, File.extname(pdf))
      full          = "#{name}_full.gif"
      thumb         = "#{name}_thumb.gif"
      icon          = "#{name}_icon.gif"
      cmds = [
        "gm convert -resize 667x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03 #{pdf} #{full}",
        "gm convert -resize 70x #{full} #{thumb}",
        "gm convert -resize 23x #{thumb} #{icon}"
      ]
      system cmds.join(' && ')
    end
    `tar -czf #{file_name}.tar *.gif`
    save("#{file_name}.tar")
  end
  
  # Merge all of the resulting images into a single tar archive, ready to
  # use in the DocumentViewer.
  def merge
    FileUtils.mkdir(["thumbs", "icons"])
    JSON.parse(input).each do |batch_url|
      batch_path = File.basename(batch_url)
      download(batch_url, batch_path)
      `tar -xzf #{batch_path}`
    end
    
    gifs = Dir['*.gif']
    output_path = File.basename(gifs[0]).sub(/_\d{4}_(full|thumb|icon)\.gif\Z/, '') + '.tar'
    
    gifs.each do |gif|
      suffix      = gif.match(/_(full|thumb|icon)\.gif\Z/)[1]
      sans_suffix = gif.sub(/_(full|thumb|icon)\.gif\Z/, '.gif')
      case suffix
      when 'full'  then FileUtils.mv(gif, sans_suffix)
      when 'thumb' then FileUtils.mv(gif, "thumbs/#{sans_suffix}")
      when 'icon'  then FileUtils.mv(gif, "icons/#{sans_suffix}")
      end
    end
    
    `tar -czf #{output_path} *.gif thumbs icons`
    save(output_path)
  end

end
