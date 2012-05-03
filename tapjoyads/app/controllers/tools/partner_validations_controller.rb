class Tools::PartnerValidationsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    all_conditions = {:include => [:payout_info, {:users => [:user_roles]}]}
    @partners = Partner.to_payout
    if params[:acct_mgr_filter].present?
      all_conditions[:conditions] = ['users.id = ?', params[:acct_mgr_filter]]
      all_conditions[:joins] = [:users]
      @account_manager = User.find(params[:acct_mgr_filter]).email
    end

    @partners = @partners.all(all_conditions)

    if params[:acct_mgr_sort].present?
      @partners = @partners.to_a
      @partners.each { |p|  class << p; attr_accessor :acct_mgr_email; end; p.acct_mgr_email =  p.account_managers.present? ? p.account_managers.first.email.downcase : "\xFF"}
      @partners.sort!{ |a,b| a.acct_mgr_email <=> b.acct_mgr_email }
      @partners.reverse! if params[:acct_mgr_sort] == 'DESC'
    end
    @partners = @partners.paginate(:page => params[:page])
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.toggle_confirmed_for_payout(current_user)
    render :json => { :success => partner.save, :was_confirmed => partner.completed_payout_info? }
  end
end
