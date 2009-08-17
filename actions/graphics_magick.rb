class GraphicsMagick < Houdini::Action
  
  def process(input, options)
    options['steps'].each do |step|
      cmd, opts = step['command'], step['options']
      `gm #{cmd} #{opts} #{input_path} #{output_path}`
    end
  end
  
end