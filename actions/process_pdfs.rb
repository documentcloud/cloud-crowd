# Depends on working pdftk, gm (GraphicsMagick), and pdftotext (Poppler) commands.
# Splits a pdf into batches of N pages, creates their thumbnails and icons,
# as specified in the Job options, gets the text for every page, and merges 
# it all back into a tar archive for convenient download.
#
# See <tt>examples/process_pdfs_example.rb</tt> for more information.
class ProcessPdfs < CloudCrowd::Action
  
  # Split up a large pdf into single-page pdfs. Batch them into 'batch_size'
  # chunks for processing. The double pdftk shuffle fixes the document xrefs.
  def split
    `pdftk #{input_path} burst output "#{file_name}_%05d.pdf_temp"`
    FileUtils.rm input_path
    pdfs = Dir["*.pdf_temp"]
    pdfs.each {|pdf| `pdftk #{pdf} output #{File.basename(pdf, '.pdf_temp')}.pdf`}
    pdfs = Dir["*.pdf"]
    batch_size = options['batch_size']
    batches = (pdfs.length / batch_size.to_f).ceil
    batches.times do |batch_num|
      tar_path = "#{sprintf('%05d', batch_num)}.tar"
      batch_pdfs = pdfs[batch_num*batch_size...(batch_num + 1)*batch_size]
      `tar -czf #{tar_path} #{batch_pdfs.join(' ')}`
    end
    Dir["*.tar"].map {|tar| save(tar) }
  end

  # Convert a pdf page into different-sized thumbnails. Grab the text.
  def process
    `tar -xzf #{input_path}`
    FileUtils.rm input_path
    cmds = []
    generate_images_commands(cmds)
    generate_text_commands(cmds)
    system cmds.join(' && ')
    FileUtils.rm Dir['*.pdf']
    `tar -czf #{file_name}.tar *`
    save("#{file_name}.tar")
  end
  
  # Merge all of the resulting images, all of the resulting text files, and
  # the concatenated merge of the full-text into a single tar archive, ready to
  # for download.
  def merge
    input.each do |batch_url|
      batch_path = File.basename(batch_url)
      download(batch_url, batch_path)
      `tar -xzf #{batch_path}`
      FileUtils.rm batch_path
    end
    
    names = Dir['*.txt'].map {|fn| fn.sub(/_\d+(_\w+)?\.txt\Z/, '') }.uniq
    dirs = names.map {|n| ["#{n}/text/full", "#{n}/text/pages"] + options['images'].map {|i| "#{n}/images/#{i['name']}" } }.flatten
    FileUtils.mkdir_p(dirs)
    
    Dir['*.*'].each do |file|
      ext = File.extname(file)
      name = file.sub(/_\d+(_\w+)?#{ext}\Z/, '')
      if ext == '.txt'
        FileUtils.mv(file, "#{name}/text/pages/#{file}")
      else
        suffix      = file.match(/_([^_]+)#{ext}\Z/)[1]
        sans_suffix = file.sub(/_([^_]+)#{ext}\Z/, ext)
        FileUtils.mv(file, "#{name}/images/#{suffix}/#{sans_suffix}")
      end
    end
    
    names.each {|n| `cat #{n}/text/pages/*.txt > #{n}/text/full/#{n}.txt` }
    
    `tar -czf processed_pdfs.tar *`
    save("processed_pdfs.tar")
  end
  
  
  private
  
  def generate_images_commands(command_list)
    Dir["*.pdf"].each do |pdf| 
      name = File.basename(pdf, File.extname(pdf))
      options['images'].each do |i|
        command_list << "gm convert #{i['options']} #{pdf} #{name}_#{i['name']}.#{i['extension']}"
      end
    end
  end
  
  def generate_text_commands(command_list)
    Dir["*.pdf"].each do |pdf|
      name = File.basename(pdf, File.extname(pdf))
      command_list << "pdftotext -enc UTF-8 -layout -q #{pdf} #{name}.txt"
    end
  end

end
