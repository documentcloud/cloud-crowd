class GraphicsMagick < Houdini::Action
  
  def initialize(*args)
    super(*args)
    @file_name = File.basename(@input, File.extname(@input))
  end
  
  def process
    `curl -s "#{@input}" > #{input_path}`
    results = []
    
    @options['steps'].each do |step|
      name, cmd, opts, ext = step['name'], step['command'], step['options'], step['extension']
      output_path = output_path_for(name, ext)
      `gm #{cmd} #{opts} #{input_path} #{output_path}`
      results << {'name' => name, 'url' => output_path}
    end
    
    results
  end
  
  def input_path
    @input_path ||= File.join(local_storage_path, File.basename(@input))
  end
  
  def output_path_for(step_name, extension)
    "#{local_storage_path}/#{@file_name}_#{step_name}.#{extension}"
  end
  
end