class Dashboard::Tools::PartnerValidationsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @partners = Partner.to_payout.includes([:payout_info, {:users => [:user_roles]}])
    if params[:acct_mgr_filter].present?
      @partners = @partners.conditions(['users.id = ? and (users.email like ? or users.email like ?)', params[:acct_mgr_filter], '%@tapjoy.com', '%@offerpal.com'])
      @partners = @partners.joins(:users)
      @account_manager = User.find(params[:acct_mgr_filter]).email
    end


    if params[:acct_mgr_sort].present?
      @partners = @partners.to_a
      if params[:acct_mgr_sort] == 'DESC'
        @partners.sort!{ |a,b| b.account_manager_email <=> a.account_manager_email }
      else
        @partners.sort!{ |a,b| a.account_manager_email <=> b.account_manager_email }
      end
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
