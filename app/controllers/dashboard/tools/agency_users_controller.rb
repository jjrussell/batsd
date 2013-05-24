class Dashboard::Tools::AgencyUsersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :get_account_managers, :only => [ :show ]

  def index
    @agency_users = UserRole.find_by_name("agency").users
  end

  def show
    @account_managers = get_account_managers
    @agency_user = User.includes(:partners => [:offers, :users, :sales_rep]).
                        find(params[:id])
    @partners = @agency_user.partners.paginate(:page => params[:page])

    manager_id = params.fetch(:managed_by, nil)
    manager_id = nil if manager_id == 'all'
    manager_id = :none if manager_id == 'none'

    @country = params.fetch(:country, nil)
    @country = nil if @country && @country.empty?
    query = params.fetch(:q, nil)
    if query
      query = query.gsub("'", '')
      query = nil if query.empty?
    end

    @partners = Partner.search(@agency_user[:id], manager_id, @country, query).
                        paginate(:page => params[:page])
  end

  private
  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort
    @account_managers.unshift(["All", "all"])
    @account_managers.push(["Not assigned", "none"])
  end
end
