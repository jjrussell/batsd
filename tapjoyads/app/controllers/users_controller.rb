class UsersController < WebsiteController
  layout 'tabbed'
  current_tab :account
  
  filter_access_to :all
  
  after_filter :save_activity_logs, :only => [ :create, :update ]
  
  def index
    @users = current_partner.users
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new
    log_activity(@user)
    
    @user.username = params[:user][:email]
    @user.email = params[:user][:email]
    pwd = UUIDTools::UUID.random_create.to_s
    @user.password = pwd
    @user.password_confirmation = pwd
    @user.current_partner = current_partner
    @user.partners << current_partner
    if @user.save
      @user.reset_perishable_token!
      TapjoyMailer.deliver_new_secondary_account(@user.email, edit_password_reset_url(@user.perishable_token))
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
    log_activity(@user)
    
    params[:user][:username] = params[:user][:email]
    if @user.safe_update_attributes(params[:user], [ :username, :email, :password, :password_confirmation, :time_zone ])
      flash[:notice] = 'Successfully updated account.'
      redirect_to users_path
    else
      render :action => :edit
    end
  end
  
end
