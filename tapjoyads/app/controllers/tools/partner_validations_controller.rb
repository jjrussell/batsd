class Tools::PartnerValidationsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all


  def index
    @partners = Partner.to_payout.all(:include => [:payout_info, :payout_info_confirmation, :payout_threshold_confirmation, {:users => [:user_roles]}])

    if params[:acct_mgr_sort]
      @partners = @partners.to_a
      @partners.each { |p|  class << p; attr_accessor :acct_mgr_email; end; p.acct_mgr_email =  p.account_managers.present? ? p.account_managers.first.email.downcase : "\xFF"}
      @partners = @partners.sort do  |a,b|
        a.acct_mgr_email <=> b.acct_mgr_email
      end
      @partners = @partners.reverse if params[:acct_mgr_sort] == 'DESC'
    end
    @partners = @partners.paginate(:page => params[:page])

  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.toggle_confirmed_for_payout(current_user)
    render :json => { :success => partner.save, :was_confirmed => partner.payout_info.present? && partner.payout_info.valid?}
  end
end
