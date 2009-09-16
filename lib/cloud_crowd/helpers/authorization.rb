module CloudCrowd
  module Helpers
    
    # Authorization takes after sinatra-authorization... See 
    # http://github.com/integrity/sinatra-authorization
    # for the original.
    module Authorization
      
      # Ensure that the request includes the correct credentials.
      def login_required
        return if authorized?
        unauthorized! unless auth.provided?
        bad_request!  unless auth.basic?
        unauthorized! unless authorize(*auth.credentials)
        request.env['REMOTE_USER'] = auth.username
      end
      
      # Has the request been authenticated?
      def authorized?
        !!request.env['REMOTE_USER']
      end
      
      # A request is authorized if its login and password match those stored
      # in config.yml, or if authentication is disabled. If authentication is
      # turned on, then every request is authenticated, including between 
      # the nodes and the central server.
      def authorize(login, password)
        return true unless CloudCrowd.config[:http_authentication]
        return CloudCrowd.config[:login] == login &&
               CloudCrowd.config[:password] == password
      end
      
      
      private
      
      # Provide a Rack Authorization object.
      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end
      
      # Unauthorized requests will prompt the browser to provide credentials.
      def unauthorized!(realm = Server.authorization_realm)
        response['WWW-Authenticate'] = "Basic realm=\"#{realm}\""
        halt 401, 'Authorization Required'
      end
      
      def bad_request!
        halt 400, 'Bad Request'
      end
    end
  end
end