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
    agency_user_role = UserRole.find_by_name('agency')
    @tapjoy_users += RoleAssignment.find(:all,
      :conditions => [ "user_role_id != ?", agency_user_role.id],
      :include => [:user]).map(&:user)
    @tapjoy_users.uniq!
  end

  def show
    @user = User.find(params[:id], :include => {
      :role_assignments => [ :user_role ],
      :partner_assignments => [ :partner ]
    })
    if permitted_to? :create, :tools_users_partner_assignments
      @partner_assignments = @user.partner_assignments.sort_by{|assignment|assignment.partner.name||''}
      @current_assignments = @user.role_assignments.sort_by{|ra| ra.user_role.name}
    end

    if permitted_to? :create, :tools_users_role_assignments
      @can_modify_roles = true
      @new_assignments = (UserRole.all - @user.user_roles).map do |user_role|
        RoleAssignment.new(:user => @user, :user_role => user_role)
      end.sort_by{|ra| ra.user_role.name}
    end
  end
end
