class PubOfferWhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all

  def index
    @whitelisted_apps = current_partner.get_offer_whitelist
    @offers = Offer.enabled_offers
  end
  
  def enable
    current_partner.add_to_whitelist(params[:offerid])
    current_partner.save!
    Rails.logger.info "*" * 100
    Rails.logger.info current_partner.offer_whitelist.inspect

    redirect_to pubwhitelist_path
  end
  
  def disable
    current_partner.remove_from_whitelist(params[:offerid])
    current_partner.save!
    redirect_to pubwhitelist_path
    
  end
end
