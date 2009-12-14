class Site::UsersController < Site::SiteController
  
  # TODO: filter password in the "Completed in" log line also. (The entire GET request is logged there)
  filter_parameter_logging :password

  def index
    user_id = params[:id]
    @user = User.new(user_id)
    unless @user
      forbidden
      return
    end
  end
  
  def login
    unless params[:user_name] and params[:password]
      forbidden
      return
    end

    items = SimpledbResource.select('user', '*', "user_name='#{params[:user_name]}'")
    @user = items[:items][0]
    Rails.logger.info "pw: " + encode_password(params[:password], @user.get('salt'))
    unless @user and verify_password(params[:password], @user.get('password'), @user.get('salt'))
     forbidden
     return
    end
    
    render 'index'
  end
  
  private
  
  def forbidden
    render :text => 'forbidden', :status => :forbidden
  end
  
  def verify_password(password, hashed_password, salt)
    hashed_password == encode_password(password, salt)
  end
  
  def encode_password(password, salt)
    unicode_password = ''
    password.each_char do |c| 
      unicode_password += c + "\x00" 
    end
    raw_salt = Base64::decode64(salt)
    sha1 = Digest::SHA1.digest(raw_salt + unicode_password)
    return Base64::encode64(sha1).strip
  end
  
end
