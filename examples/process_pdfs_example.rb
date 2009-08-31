RestClient.post(
	'http://localhost:9173/jobs',
	{:job => {
	
		'action' => 'process_pdfs',
		
		'inputs' => [
		  'http://tigger.uic.edu/~victor/personal/futurism.pdf',
		  'http://www.jonasmekas.com/Catalog_excerpt/The%20Avant-Garde%20From%20Futurism%20to%20Fluxus.pdf',
		  'http://www.dzignism.com/articles/Futurist.Manifesto.pdf'
		],
		
		'options' => {
		  
		  'batch_size' => 7,
		  		  
		  'images' => [{
				'name' 			=> '700',
				'options'		=> '-resize 700x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03',
				'extension' => 'gif'
			},{
				'name' 			=> '1000',
				'options'		=> '-resize 1000x -density 220 -depth 4 -unsharp 0.5x0.5+0.5+0.03',
				'extension' => 'gif'
			}]
		  
		}
		
	}.to_json}
)
