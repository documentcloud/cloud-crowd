require 'json'

puts RestClient.post(
	'http://ec2-75-101-213-115.compute-1.amazonaws.com/jobs', 
	{:json => {
	
		'action' => 'pdf_to_images',
		
		'inputs' => [
		  'http://s3.amazonaws.com/dogpile_development/pdfs/bigtable-osdi06.pdf',
		  'http://s3.amazonaws.com/dogpile_development/pdfs/DocumentCloud_As_Submitted.pdf'
		]
		
	}.to_json}
)
