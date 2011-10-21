class PasswordResetsController < WebsiteController

  before_filter :require_no_user
  before_filter :find_user_using_perishable_token, :only => [ :edit, :update ]

  def new
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.reset_perishable_token!
      TapjoyMailer.deliver_password_reset(@user.email, edit_password_reset_url(@user.perishable_token))
      flash.now[:notice] = "A password reset link has just been emailed to you. Please check your email."
    else
      flash.now[:error] = "No user found with that email address."
    end
    render :action => :new
  end

  def edit
  end

  def update
    if @user.safe_update_attributes(params[:user], [ :password, :password_confirmation ])
      flash[:notice] = "Password successfully updated."
      redirect_to users_path
    else
      render :action => :edit
    end
  end

private

  def require_no_user
    unless current_user.nil?
      flash[:error] = "You must be logged out to reset passwords."
      redirect_to users_path
    end
  end

  def find_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    if @user.nil?
      flash[:error] = "Your password reset token has expired. Please use the 'Forgot password?' link below to request a new one."
      redirect_to login_path
    end
  end

end
