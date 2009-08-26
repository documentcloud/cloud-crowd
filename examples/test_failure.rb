require 'json'

RestClient.post(
	'http://localhost:9173/jobs', 
	{:json => {
    'action'  => 'failure_testing',
    'inputs'  => ['one', 'two', 'three'],
    'options' => {}
	}.to_json}
)