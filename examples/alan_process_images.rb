require 'json'

images = ('0001'..'0658').map {|num| "http://graphics8.nytimes.com/packages/images/nytint/docs/geithner-schedule-new-york-fed/#{num}.gif"}

RestClient.post(
	'http://localhost:9173/jobs', 
	{:json => {
	
		'action' => 'graphics_magick',
		
		'inputs' => images,
		
		'options' => {
			'steps' => [{
				'name' 			=> '0',
				'command' 	=> 'convert',
				'options'		=> '-format PNG8 -colorspace GRAY',
				'extension' => 'png'
			},{
				'name' 			=> '5',
				'command' 	=> 'convert',
				'options'		=> '-format PNG8 -colorspace GRAY -scale 105%x105%',
				'extension' => 'png'
			},{
				'name' 			=> '10',
				'command' 	=> 'convert',
				'options'		=> '-format PNG8 -colorspace GRAY -scale 110%x110% -sharpen 3x2',
				'extension' => 'png'
			},{
				'name' 			=> '15',
				'command' 	=> 'convert',
				'options'		=> '-format PNG8 -colorspace GRAY -scale 115%x115% -sharpen 4x2',
				'extension' => 'png'
			},{
				'name' 			=> '20',
				'command' 	=> 'convert',
				'options'		=> '-format PNG8 -colorspace GRAY -scale 120%x120% -sharpen 5x3',
				'extension' => 'png'
			}]
		}
		
	}.to_json}
)
