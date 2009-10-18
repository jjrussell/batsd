# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f9a08830b0e4e7191cd93d2e02b08187'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  private
  def cache(key)
    output = nil
    begin
      output = CACHE.get(key)
      unless
        puts "unless"
        output = yield
      end
    rescue Memcached::NotFound
      puts 'notfound'
      output = yield
    end
    
    CACHE.set(key, output, 1.hour)
    return output
  end
end
