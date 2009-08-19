# The GraphicsMagick action, dependent on the `gm` command, is able to perform
# any number of GraphicsMagick conversions on an image passed in as an input.
# The options hash should specify the +name+ for the particular step (which is
# appended to the resulting image filename) the +command+ (eg. convert, mogrify), 
# the +options+ (to the command, eg. -shadow -blur), and the +extension+ which 
# will determine the resulting image type. Optionally, you may also specify
# +input+ as the name of a previous step; doing this will use the result of
# that step as the source image, otherwise each step uses the original image
# as its source.
class GraphicsMagick < Dogpile::Action
  
  def initialize(*args)
    super(*args)
    @file_name = File.basename(@input, File.extname(@input))
  end
  
  # Download the initial image, and run each of the specified GraphicsMagick
  # commands against it.
  def run
    `curl -s "#{@input}" > #{input_path_for(nil)}`
    @options['steps'].map {|step| run_step(step) }
  end
  
  # Run an individual step (single GraphicsMagick command) in a shell-injection
  # safe way, uploading the result to the AssetStore, and returning the public
  # URL as the result.
  # TODO: +system+ wasn't working, figure out some other way to escape.
  def run_step(step)
    name, cmd, opts, ext = step['name'], step['command'], step['options'], step['extension']
    input_path = input_path_for(step)
    output_path = output_path_for(name, ext)
    storage_path = storage_path_for(name, ext)
    `gm #{cmd} #{opts} #{input_path} #{output_path}`
    @store.save(output_path, storage_path)
    {'name' => name, 'url' => @store.url(storage_path)}
  end
  
  # Where should the initial image be located?
  # If you pass in an optional step, returns the path to that step's output
  # as input for further processing.
  def input_path_for(step=nil)
    in_step = step && step['input'] && @options['steps'].detect {|s| s['name'] == step['input']}
    return @input_path ||= File.join(temp_storage_path, File.basename(@input)) unless in_step
    return output_path_for(in_step['name'], in_step['extension'])
  end
  
  # Where should resulting images be saved locally?
  def output_path_for(step_name, extension)
    "#{temp_storage_path}/#{@file_name}_#{step_name}.#{extension}"
  end
  
  # Where should resulting images be saved in permanent storage?
  def storage_path_for(step_name, extension)
    "#{s3_storage_path}/#{@file_name}_#{step_name}.#{extension}"
  end
  
end