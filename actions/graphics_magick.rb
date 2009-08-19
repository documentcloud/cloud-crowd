# The GraphicsMagick action, dependent on the `gm` command, is able to perform
# any number of GraphicsMagick conversions on an image passed in as an input.
# The options hash should specify the name for the particular step (which is
# appended to the resulting image filename) the command (eg. convert, mogrify), 
# the options (to the command, eg. -shadow -blur), and the extension which will
# determine the resulting image type.
class GraphicsMagick < Dogpile::Action
  
  def initialize(*args)
    super(*args)
    @file_name = File.basename(@input, File.extname(@input))
  end
  
  def run
    `curl -s "#{@input}" > #{input_path}`
    results = []
    
    @options['steps'].each do |step|
      name, cmd, opts, ext = step['name'], step['command'], step['options'], step['extension']
      output_path = output_path_for(name, ext)
      storage_path = storage_path_for(name, ext)
      `gm #{cmd} #{opts} #{input_path} #{output_path}`
      @store.save(output_path, storage_path)
      results << {'name' => name, 'url' => @store.url(storage_path)}
    end
    
    results
  end
  
  def input_path
    @input_path ||= File.join(temp_storage_path, File.basename(@input))
  end
  
  def output_path_for(step_name, extension)
    "#{temp_storage_path}/#{@file_name}_#{step_name}.#{extension}"
  end
  
  def storage_path_for(step_name, extension)
    "#{s3_storage_path}/#{@file_name}_#{step_name}.#{extension}"
  end
  
end