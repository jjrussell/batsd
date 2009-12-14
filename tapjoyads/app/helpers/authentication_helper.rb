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
end
