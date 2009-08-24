class PdfToImages < Dogpile::Action
  
  def run
    starting_dir = Dir.pwd
    tar_path = "#{work_directory}/#{file_name}.tar"
    `gm convert -format PNG8 #{input_path} #{work_directory}/%04d.png`
    Dir.chdir work_directory # Can't get -C to work.
    `tar -czf #{tar_path} *.png` 
    Dir.chdir Dir.pwd 
    save(tar_path)
  end
  
end