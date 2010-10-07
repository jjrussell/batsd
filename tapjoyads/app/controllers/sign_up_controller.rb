class SignUpController < WebsiteController

  def new
    redirect_to users_path if current_user
    @user = User.new
  end

  def create
    @user = User.new
    @user.username = @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.current_partner = Partner.new(:name => params[:partner_name], :contact_name => @user.email)
    @user.time_zone = params[:user][:time_zone]
    @user.partners << @user.current_partner
    if @user.save
      flash[:notice] = 'Account successfully created.'
      redirect_to apps_path
    else
      render :action => :new
    end
  end

end
