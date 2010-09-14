class UsersController < WebsiteController
  layout 'tabbed'
  current_tab :account
  
  filter_access_to :all
  
  def index
    @users = current_partner.users
  end
  
  def new
    @user = User.new
    render 'new', :layout => 'website'
  end
  
  def create
    @user = User.new
    @user.username = params[:user][:email]
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.current_partner = current_partner || Partner.new
    @user.partners << @user.current_partner
    if @user.save
      @user.user_roles << UserRole.find_by_name("beta_website")
      flash[:notice] = 'Account successfully created.'
      redirect_to users_path
    else
      render 'new', :layout => 'website'
    end
  end
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    if @user.safe_update_attributes(params[:user], [ :email, :password, :password_confirmation ])
      flash[:notice] = 'Successfully updated account.'
      redirect_to users_path
    else
      render :action => :edit
    end
  end
  
end
