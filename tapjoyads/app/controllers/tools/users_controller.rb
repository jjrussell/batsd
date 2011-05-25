class Tools::UsersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @tapjoy_users = User.find(:all,
      :conditions => [ "email LIKE ? AND email NOT LIKE ?", "%@tapjoy.com", "%+%" ],
      :include => { :role_assignments => [ :user_role ] },
      :order => 'email ASC').paginate(:page => params[:page], :per_page => 100)
  end

  def show
    @user = User.find(params[:id], :include => {
      :role_assignments => [ :user_role ]
    })
    @new_assignments = (UserRole.all - @user.user_roles).map do |user_role|
      RoleAssignment.new(:user => @user, :user_role => user_role)
    end.sort_by{|ra| ra.user_role.name}
    @current_assignments = @user.role_assignments.sort_by{|ra| ra.user_role.name}
  end
end
