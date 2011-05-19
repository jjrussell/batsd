class Account::WhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :account
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :enable, :disable ]  

  def index
    redirect_to apps_path unless current_partner.use_whitelist?
    @whitelisted_offers = current_partner.get_offer_whitelist
    all_offers = Offer.enabled_offers.by_name(params[:name]).by_device(params[:device] == "all" ? "" : params[:device]).sort_by {|offer| offer.name}
    approved_offers = all_offers.reject { |offer| !@whitelisted_offers.include?(offer.id) }
    blocked_offers = all_offers.reject { |offer| @whitelisted_offers.include?(offer.id) }
    case params[:status]
    when "a": @offers = approved_offers
    when "b": @offers = blocked_offers
    else @offers = approved_offers + blocked_offers
    end
  end
  
  def enable
    redirect_to apps_path unless current_partner.use_whitelist?
    log_activity(current_partner)
    current_partner.add_to_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end
  
  def disable
    redirect_to apps_path unless current_partner.use_whitelist?
    log_activity(current_partner)
    current_partner.remove_from_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end
  
class ItemForWhitelistSort
  def initialize( item )
    @item = item
  end
  def item
    @item
  end
  def <=>( target )
    ( self.item <=> target.item ) * (-1)
  end
end  
end
