# The GraphicsMagick action, dependent on the `gm` command, is able to perform
# any number of GraphicsMagick conversions on an image passed in as an input.
# The options hash should specify the +name+ for the particular step (which is
# appended to the resulting image filename) the +command+ (eg. convert, mogrify), 
# the +options+ (to the command, eg. -shadow -blur), and the +extension+ which 
# will determine the resulting image type. Optionally, you may also specify
# +input+ as the name of a previous step; doing this will use the result of
# that step as the source image, otherwise each step uses the original image
# as its source.
class GraphicsMagick < CloudCrowd::Action
  
  # Download the initial image, and run each of the specified GraphicsMagick
  # commands against it, returning the aggregate output.
  def process
    options['steps'].inject({}) {|h, step| h[step['name']] = run_step(step); h }
  end
  
  # Run an individual step (single GraphicsMagick command) in a shell-injection
  # safe way, uploading the result to the AssetStore, and returning the public
  # URL as the result.
  # TODO: +system+ wasn't working, figure out some other way to escape.
  def run_step(step)
    cmd, opts = step['command'], step['options']
    in_path, out_path = input_path_for(step), output_path_for(step)
    `gm #{cmd} #{opts} #{in_path} #{out_path}`
    save(out_path)    
  end
  
  # Where should the starting image be located?
  # If you pass in an optional step, returns the path to that step's output
  # as input for further processing.
  def input_path_for(step)
    in_step = step && step['input'] && options['steps'].detect {|s| s['name'] == step['input']}
    return input_path unless in_step
    return output_path_for(in_step)
  end
  
  # Where should resulting images be saved locally?
  def output_path_for(step)
    "#{work_directory}/#{file_name}_#{step['name']}.#{step['extension']}"
  end
  
end