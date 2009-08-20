require 'json'

RestClient.post(
	'http://localhost:9173/jobs', 
	{:json => JSON.generate({
    'action'  => 'failure_testing',
    'inputs'  => ['one', 'two', 'three'],
    'options' => {}
	})}
)