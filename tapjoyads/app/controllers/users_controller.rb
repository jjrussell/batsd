class UsersController < WebsiteController
  layout 'tabbed'
  current_tab :account
  
  filter_access_to :all
  
  def index
    @users = current_partner.users
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new
    @user.username = params[:user][:username]
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.current_partner = current_partner
    @user.partners << current_partner
    if @user.save
      flash[:notice] = 'Account successfully created.'
      redirect_to users_path
    else
      render :action => :new
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
