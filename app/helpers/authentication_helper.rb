module AuthenticationHelper

  private

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

  def pocketgems_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'pocketgems'
        password = 'saP3UkA8adRa'
      end
      password
    end
  end

  def sgn_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'sgn'
        password = 'h58ck120xhb3'
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

  def glu_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'glu'
        password = 'j348h83hngs84hsla8hskri56h'
      end
      password
    end
  end

  def fluent_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'fluent'
        password = 'nbuh24098uf2lk23ub'
      end
      password
    end
  end

  def ngmoco_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'ngmoco'
        password = 'oasB5l038gpq2p3AjY'
      end
      password
    end
  end

  def gogii_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'gogii'
        password = 'pMWl3M9jsgp0'
      end
      password
    end
  end

  def loopt_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'loopt'
        password = '0t20yr6C5LnN'
      end
      password
    end
  end

  def adways_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'adways'
        password = 'ed37P7YL2Nqs'
      end
      password
    end
  end

  def brooklyn_packet_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'brooklyn_packet'
        password = 'hU2AzeTayUsu'
      end
      password
    end
  end

  def ea_authenticate
    authenticate_or_request_with_http_digest do |username|
      if username == 'ea'
        password = 'SPE6uq9n6KaF'
      end
      password
    end
  end

end
