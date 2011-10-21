class Account::WhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :account
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :enable, :disable ]
  before_filter :check_whitelist_access, :only => [ :index, :enable, :disable ]

  def index
    @whitelisted_offers = current_partner.get_offer_whitelist
    all_offers = Offer.enabled_offers.by_name(params[:name]).by_device(params[:device] == "all" ? "" : params[:device]).sort_by {|offer| offer.name}
    approved_offers = all_offers.reject { |offer| !@whitelisted_offers.include?(offer.id) }
    blocked_offers = all_offers.reject { |offer| @whitelisted_offers.include?(offer.id) }
    @offers  = case params[:status]
    when "a"
      approved_offers
    when "b"
      blocked_offers
    else
      approved_offers + blocked_offers
    end
  end

  def enable
    log_activity(current_partner)
    current_partner.add_to_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end

  def disable
    log_activity(current_partner)
    current_partner.remove_from_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end

private

  def check_whitelist_access
    redirect_to apps_path unless current_partner.use_whitelist?
  end

end
