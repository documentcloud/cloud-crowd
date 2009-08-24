require 'json'

pdfs = Dir['/Users/jashkenas/Desktop/document_cloud/*.pdf'].map {|pdf| "file://#{pdf}"}

RestClient.post(
	'http://localhost:9173/jobs', 
	{:json => {
	
		'action' => 'document_cloud_import',
		
		'inputs' => pdfs,
		
		'options' => {}
		
	}.to_json}
)
