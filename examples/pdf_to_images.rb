require 'json'

RestClient.post(
	'http://localhost:9173/jobs', 
	{:json => {
	
		'action' => 'pdf_to_images',
		
		'inputs' => [
		  'http://s3.amazonaws.com/dogpile_development/pdfs/bigtable-osdi06.pdf',
		  'http://s3.amazonaws.com/dogpile_development/pdfs/DocumentCloud_As_Submitted.pdf'
		]
		
	}.to_json}
)
