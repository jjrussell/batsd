module AuthenticationHelper
  USERS = {
    'cron' => 'y7jF0HFcjPq'
  }
  
  def authenticate
    authenticate_or_request_with_http_digest do |username|
      USERS[username]
    end
  end
end
