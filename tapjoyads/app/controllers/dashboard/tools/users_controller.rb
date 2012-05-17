class Dashboard::Tools::UsersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @tapjoy_users = User.internal_users.sort_by do |user|
      [user.role_assignments.blank? ? 1 : 0, user.email.downcase]
    end
    @tapjoy_users += User.external_users_with_roles
    @tapjoy_users.uniq!
  end

  def show
    @user = User.find(params[:id], :include => {
      :role_assignments => [ :user_role ],
      :partner_assignments => [ :partner ]
    })

    if permitted_to? :create, :dashboard_tools_partner_assignments
      @partner_assignments = @user.partner_assignments.sort
      @current_assignments = @user.role_assignments.sort
    end

    if permitted_to? :create, :dashboard_tools_role_assignments
      @can_modify_roles = true
      @new_assignments = (UserRole.all - @user.user_roles).map do |user_role|
        RoleAssignment.new(:user => @user, :user_role => user_role)
      end.sort
    end
  end
end
