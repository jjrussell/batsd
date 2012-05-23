class Dashboard::Tools::PartnerValidationsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @filter_options = [['All',''],['Unconfirmed - Actionable', '1'],['Unconfirmed - All', '2'], ['Confirmed', '3']]
    @partners = Partner.to_payout

    @partners = @partners.includes(:payout_info, { :users => :user_roles })
    if params[:acct_mgr_filter].present?
      @partners = @partners.where(["#{User.quoted_table_name}.id = ? and (#{User.quoted_table_name}.email like ? or #{User.quoted_table_name}.email like ?)", params[:acct_mgr_filter], '%@tapjoy.com', '%@offerpal.com'])
      @partners = @partners.joins(:users)
      @account_manager = User.find(params[:acct_mgr_filter]).email
    end

    if params[:confirm_filter].present?
      if params[:confirm_filter] == '1'
        @partners = @partners.where(:payout_threshold_confirmation => 0)
      elsif params[:confirm_filter] == '2'
        @partners = @partners.where("#{Partner.quoted_table_name}.payout_threshold_confirmation = 0 OR #{Partner.quoted_table_name}.payout_info_confirmation = 0 OR #{PayoutInfo.quoted_table_name}.id is null") #should be unconfirmed
      else
        @partners = @partners.where(:payout_threshold_confirmation => 1, :payout_info_confirmation => 1).where("#{PayoutInfo.quoted_table_name}.id is not null")
      end
    end


    if params[:acct_mgr_sort].present?
      #Finding all of the users that are account managers or admins and joining in sql, since paginate requires Arel and will not work on Arrays in Rails 3
      @partners = @partners.joins(:users).joins("LEFT OUTER JOIN (select distinct(u.id) as id, ucase(u.email) as email  from #{User.quoted_table_name} u inner join #{RoleAssignment.quoted_table_name} ra on u.id = ra.user_id  where ra.user_role_id = 'f905d9e3-2be5-4755-84e4-ebfb1ba8f605' OR ra.user_role_id = 'a336df9e-bcb9-4917-9470-91cea4400b88') as acct_mgrs on #{PartnerAssignment.quoted_table_name}.user_id = acct_mgrs.id")
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
    render :json => { :success => partner.save, :was_confirmed =>  partner.confirmation_notes.blank?, :notes => partner.confirmation_notes, :can_confirm => partner.can_be_confirmed?(current_user) }
  end
end
