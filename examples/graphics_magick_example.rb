# Inside of a restclient session:
# This is a fancy example that produces black and white, annotated, and blurred
# versions of a list of URLs downloaded from the web.

require 'json'

RestClient.post(
	'http://localhost:9173/jobs', 
	{:job => {
	
		'action' => 'graphics_magick',
		
		'inputs' => [
			'http://www.sci-fi-o-rama.com/wp-content/uploads/2008/10/dan_mcpharlin_the_land_of_sleeping_things.jpg',
			'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread01.jpg',
			'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread03.jpg',
			'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/07/dan_mcpharlin_wired_spread02.jpg',
			'http://www.sci-fi-o-rama.com/wp-content/uploads/2009/02/dan_mcpharlin_untitled.jpg'
		],
		
		'options' => {
			'steps' => [{
				'name' 			=> 'annotated',
				'command' 	=> 'convert',
				'options'		=> '-font helvetica -fill red -draw "font-size 35; text 75,75 CloudCrowd!"',
				'extension' => 'jpg'
			},{
				'name'			=> 'blurred',
				'command' 	=> 'convert',
				'options'		=> '-blur 10x5',
				'extension' => 'png'
			},{
				'name' 			=> 'bw', 
				'input'			=> 'blurred',
				'command' 	=> 'convert', 
				'options' 	=> '-monochrome', 
				'extension' => 'jpg'
			}]
		}
		
	}.to_json}
)

# status = RestClient.get('http://localhost:9173/jobs/[job_id]')

# puts JSON.parse(RestClient.get('http://localhost:9173/jobs/[job_id]'))['outputs'].values.map {|v| 
#		JSON.parse(v).map {|v| v['url']} 
#	}.flatten.join("\n")