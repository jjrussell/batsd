class Dashboard::Tools::PartnerValidationsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @partners = Partner.to_payout.includes(:payout_info, { :users => :user_roles })
    if params[:acct_mgr_filter].present?
      @partners = @partners.conditions(['users.id = ? and (users.email like ? or users.email like ?)', params[:acct_mgr_filter], '%@tapjoy.com', '%@offerpal.com'])
      @partners = @partners.joins(:users)
      @account_manager = User.find(params[:acct_mgr_filter]).email
    end

    if params[:acct_mgr_sort].present?
      #Finding all of the users that are account managers or admins and joining in sql, since paginate requires Arel and will not work on Arrays in Rails 3
      @partners = @partners.joins(:users).joins("LEFT OUTER JOIN (select distinct(u.id) as id, ucase(u.email) as email  from users u inner join role_assignments ra on u.id = ra.user_id  where ra.user_role_id = 'f905d9e3-2be5-4755-84e4-ebfb1ba8f605' OR ra.user_role_id = 'a336df9e-bcb9-4917-9470-91cea4400b88') as acct_mgrs on partner_assignments.user_id = acct_mgrs.id")
      order = params[:acct_mgr_sort] == 'DESC' ? 'DESC' : 'ASC'
      #DANGER: This utilizes a MYSQL-specific call for casting a utf8 character to properly sort on emails compared to nulls
      @partners = @partners.reorder("COALESCE(acct_mgrs.email,CHAR(0xE381A6 using utf8)) #{order}")
    end
    @partners = @partners.paginate(:page => params[:page])
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.confirm_for_payout(current_user)
    render :json => { :success => partner.save, :was_confirmed =>  partner.confirmation_notes.blank?, :notes => "- #{partner.confirmation_notes.join('<br>- ')}", :can_confirm => partner.can_be_confirmed?(current_user) }
  end
end
