class Site::UsersController < Site::SiteController
  
  filter_parameter_logging :password
  
  #GET /site/users/:id.xml  
  def show
    user_id = params[:id]
    @user = User.new(user_id)
    
    respond_to do |format|
      if @user.get('user_name')
        format.xml #show.builder
      else
        format.xml {render :xml => {:message => "Resource Not found"}.to_xml(:root => "User"), :status => 404} 
      end
    end
  end
  
  #POST /site/users/login.xml   
  def login    
    success = true
    success = false unless params[:user_name] and params[:password]                
    if success      
      items = SimpledbResource.select('user', '*', "user_name='#{params[:user_name]}'")
      @user = items[:items][0]      
      success = false unless @user and verify_password(params[:password], @user.get('password'), @user.get('salt'))            
    end    
    
    respond_to do |format|
      if success
        format.xml #login.builder
      else
        format.xml {forbidden}
      end
    end    
  end
  
  def create
    
  end
  
  private
  
  def forbidden
    render :xml => {:message => "Forbidden access"}, :status => :forbidden
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
