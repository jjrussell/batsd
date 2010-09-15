class SignUpController < WebsiteController

  def new
    redirect_to account_index_path if current_user
    @user = User.new
  end

  def create
    @user = User.new
    @user.username = params[:user][:username]
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.user_roles << UserRole.find_by_name("beta_website")
    @user.current_partner = Partner.new
    @user.partners << @user.current_partner
    if @user.save
      flash[:notice] = 'Account successfully created.'
      redirect_to users_path
    else
      render 'new', :layout => 'website'
    end
  end

end
