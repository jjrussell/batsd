class Tools::AgencyUsersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :get_account_managers, :only => [ :show ]
  
  def index
    @agency_users = UserRole.find_by_name("agency").users
  end

  def show
    @pid=params[:id]
    @agency_user = User.find(params[:id])
    #render(:partial => 'shared/_partner_table', :locals => {:partners => @agency_user.partners})
    
  end

private
  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort
    @account_managers.unshift(["All", "all"])
    @account_managers.push(["Not assigned", "none"])
  end
end