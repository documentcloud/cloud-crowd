class PdfToImages < Dogpile::Action

  def run
    starting_dir = File.expand_path(Dir.pwd)
    tar_path = "#{work_directory}/#{file_name}.tar"
    `mkdir #{work_directory}/thumbs`
    `mkdir #{work_directory}/icons`
    
    `gm convert -resize 667x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03 #{input_path} #{work_directory}/%04d.gif`
    
    Dir["#{work_directory}/*.gif"].each do |gif|
      `gm convert -resize 70x #{gif} #{work_directory}/thumbs/#{File.basename(gif)}`
    end
    
    Dir["#{work_directory}/thumbs/*.gif"].each do |gif|
      `gm convert -resize 23x #{gif} #{work_directory}/icons/#{File.basename(gif)}`
    end

    Dir.chdir work_directory # Can't get -C to work.
    `tar -czf #{tar_path} *.gif thumbs icons`
    Dir.chdir starting_dir
    save(tar_path)
  end

end
