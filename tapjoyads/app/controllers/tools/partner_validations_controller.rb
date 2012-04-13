class Tools::PartnerValidationsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @partners = Partner.to_payout.all( :include => [:payout_info, :payout_info_confirmation, :payout_threshold_confirmation])
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.toggle_confirmed_for_payout
    render :json => { :success => partner.save, :was_confirmed => partner.payout_info.present? && partner.payout_info.valid?}
  end
end
