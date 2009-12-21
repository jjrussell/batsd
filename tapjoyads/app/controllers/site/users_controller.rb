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
        format.xml {not_found("user")} 
      end
    end
  end
  #POST /site/users.xml
  def create    
    #TODO: create a new user here need to implement errors so they can be sent
    #back to ARes client     
    respond_to do |format|
      if @user.save        
        #TODO: to_xml implemented in user model should be in parent class
        format.xml  {render :xml => @user, :status => :created }
      else
        #TODO: implement errors collection as Hash
        format.xml  { render @user.errors, :status => :unprocessable_entity } 
      end
    end
  end
  
  #POST /site/users/login.xml   
  def login    
    success = true
    success = false unless params[:user][:user_name] and params[:user][:password]                
    if success      
      items = SimpledbResource.select('user', '*', "user_name='#{params[:user][:user_name]}'")
      @user = items[:items][0]
      success = false unless @user and verify_password(params[:user][:password], @user.get('password'), @user.get('salt'))            
    end    
    
    respond_to do |format|
      if success
        format.xml #login.builder
      else
        format.xml {forbidden("user")}
      end
    end    
  end
    
  private
    
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
