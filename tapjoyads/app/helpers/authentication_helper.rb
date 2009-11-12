module AuthenticationHelper
  USERS = {
    'internal' => 'r3sU0oQav2Nl'
  }
  
  def authenticate
    authenticate_or_request_with_http_digest do |username|
      USERS[username]
    end
  end
end
