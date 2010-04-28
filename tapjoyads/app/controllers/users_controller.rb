class UsersController < WebsiteController
  
  before_filter :ensure_current_user, :only => [ :edit, :update ]
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Successfully updated password.'
      redirect_to tools_path
    else
      render :action => 'edit'
    end
  end

private
  
  def ensure_current_user
    unless current_user
      flash[:error] = 'You must be logged in.'
      redirect_to login_path
    end
  end
  
end
