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
      username == 'tapjoy' && password == '02P3jsH2opPl'
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
  
  def tapulous_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'tapulous'
        password = 'TTR3ftw'
      end
      password
    end
  end
  
  def streetview_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'streetview'
        password = '*streetviewlabsisawesome!'
      end
      password
    end
  end
  
  def pinger_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'pinger'
        password = 'b3fegE?a'
      end
      password
    end
  end

  def zynga_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'zynga'
        password = 'b73kshg2aksjdfh84'
      end
      password
    end
  end
  
end
