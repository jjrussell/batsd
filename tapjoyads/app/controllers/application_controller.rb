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
  def get_from_cache_and_save(key)
    value = get_from_cache(key) do
      yield
    end
    
    save_to_cache(key, value)
    
    return value
  end
  
  def get_from_cache(key)
    value = nil
    begin
      value = CACHE.get(key)
      logger.info("Memcache key found: #{key}")
    rescue Memcached::NotFound
      logger.info("Memcache key not found: #{key}")
    end
    
    unless value
      value = yield
    end
    
    return value
  end
  
  def save_to_cache(key, value)
    if value
      CACHE.set(key, value, 1.hour)
    end
  end
  
  def authenticate_cron
    authenticate_or_request_with_http_digest do |username|
      'y7jF0HFcjPq'
    end
  end
end
