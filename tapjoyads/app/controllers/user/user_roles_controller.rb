class User::UserRolesController < UserController
  filter_resource_access
  
  def index
    @user_roles = UserRole.paginate(:page => params[:page])
  end
  
  def new
  end
  
  def create
    if @user_role.save
      flash[:notice] = 'Successfully created user role.'
      redirect_to user_user_roles_path
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @user_role.update_attributes(params[:user_role])
      flash[:notice] = 'Successfully updated user role.'
      redirect_to user_user_roles_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @user_role.destroy
    flash[:notice] = 'Successfully destroyed user role.'
    redirect_to user_user_roles_path
  end
  
end
