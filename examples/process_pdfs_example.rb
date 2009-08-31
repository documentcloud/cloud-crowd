RestClient.post(
	'http://localhost:9173/jobs',
	{:json => {
	
		'action' => 'process_pdfs',
		
		'inputs' => [
		  'http://tigger.uic.edu/~victor/personal/futurism.pdf',
		  'http://www.jonasmekas.com/Catalog_excerpt/The%20Avant-Garde%20From%20Futurism%20to%20Fluxus.pdf',
		  'http://www.dzignism.com/articles/Futurist.Manifesto.pdf'
		],
		
		'options' => {
		  
		  'batch_size' => 7,
		  		  
		  'images' => [{
				'name' 			=> 'normal',
				'options'		=> '-resize 700x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03',
				'extension' => 'gif'
			},{
				'name' 			=> 'large',
				'options'		=> '-resize 1050x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03',
				'extension' => 'gif'
			}]
		  
		}
		
	}.to_json}
)
