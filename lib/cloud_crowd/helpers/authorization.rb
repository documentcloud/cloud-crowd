# After sinatra-authorization...

module CloudCrowd
  module Helpers
    module Authorization
      
      def login_required
        return if authorized?
        unauthorized! unless auth.provided?
        bad_request!  unless auth.basic?
        unauthorized! unless authorize(*auth.credentials)
        request.env['REMOTE_USER'] = auth.username
      end
      
      def authorized?
        !!request.env['REMOTE_USER']
      end
      
      def current_user
        request.env['REMOTE_USER']
      end
      
      def authorize(login, password)
        return true unless CloudCrowd.config[:use_authentication]
        return CloudCrowd.config[:login] == login &&
               CloudCrowd.config[:password] == password
      end
      
      
      private
      
      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end
      
      def unauthorized!(realm = CloudCrowd::App.authorization_realm)
        response['WWW-Authenticate'] = "Basic realm=\"#{realm}\""
        halt 401, 'Authorization Required'
      end
      
      def bad_request!
        halt 400, 'Bad Request'
      end
    end
  end
end