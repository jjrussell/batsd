module AuthenticationHelper
  USERS = {
    'internal' => 'r3sU0oQav2Nl'
  }
  
  def authenticate(allowed_users = nil)
    authenticate_or_request_with_http_digest do |username|
      if allowed_users.nil? or allowed_users.include?(username)
        password = USERS[username]
      end
      password
    end
  end
  
  def basic_authenticate(allowed_users = nil)
    authenticate_or_request_with_http_basic do |username, password|
      username == 'website' && password == '91karWQpaN5q'
    end
  end
  
  def sales_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'sales'
        'uew862nvm01ds'
      else
        USERS[username]
      end
    end
  end
end
