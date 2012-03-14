class Tools::Users::RoleAssignmentsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :find_role_assignment
  after_filter :save_activity_logs, :only => [ :create, :destroy ]

  def create
    if @user_role.admin?
      flash[:error] = "Admin roles cannot be added with this tool"
    elsif @user.user_roles << @user_role
      flash[:notice] = "<b>#{@user.email}</b> now has <b>#{@user_role.name}</b> privilege."
    else
      flash[:error] = "could not add <b>#{@user_role.name}</b> privilege from <b>#{@user.email}</b>."
    end
    redirect_to tools_user_path(@user.id)
  end

  def destroy
    if @user_role.admin?
      flash[:error] = "Admin roles cannot be revoked with this tool"
    elsif @user.user_roles.delete(@user_role)
      flash[:notice] = "<b>#{@user.email}</b> no longer has <b>#{@user_role.name}</b> privilege."
    else
      flash[:error] = "could not revoke <b>#{@user_role.name}</b> privilege from <b>#{@user.email}</b>."
    end
    redirect_to tools_user_path(@user.id)
  end

  private
  def find_role_assignment
    @user = User.find(params[:user_id])
    if params[:id].present?
      @role_assignment = @user.role_assignments.find_by_id(params[:id])
    else
      @role_assignment = @user.role_assignments.build(:user_role_id => params[:user_role_id])
    end
    @user_role = @role_assignment.user_role
    log_activity(@user, :included_methods => [ :role_symbols ])
  end
end
