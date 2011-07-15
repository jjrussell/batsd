class Tools::UsersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @tapjoy_users = User.find(:all,
      :conditions => [ "( email LIKE ? OR email LIKE ? ) AND email NOT LIKE ?",
        "%@tapjoy.com", "%offerpal.com", "%+%" ],
      :include => { :role_assignments => [ :user_role ] }).sort_by do |user|
        [user.user_roles.blank? ? 1 : 0, user.email.downcase]
      end
  end

  def show
    @user = User.find(params[:id], :include => {
      :role_assignments => [ :user_role ],
      :partner_assignments => [ :partner ]
    })
    @partner_assignments = @user.partner_assignments.sort_by{|assignment|assignment.partner.name||''}
    @current_assignments = @user.role_assignments.sort_by{|ra| ra.user_role.name}

    if permitted_to? :create, :tools_users_role_assignments
      @can_modify_roles = true
      @new_assignments = (UserRole.all - @user.user_roles).map do |user_role|
        RoleAssignment.new(:user => @user, :user_role => user_role)
      end.sort_by{|ra| ra.user_role.name}
    end
  end
end
