class PubOfferWhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all

  def index
    
    @whitelistedapps = current_partner.get_offer_whitelist

    
    @offers = Offer.enabled_offers
    
  end
  
  def enable
    partner = current_partner
    currentApprovedList = partner.get_offer_whitelist
    currentApprovedList.add(params[:offerid])
    partner.offer_whitelist = currentApprovedList.to_a.join(';')
    partner.save!
    redirect_to pubwhitelist_path
  end
  
  def disable
    partner = current_partner
    currentApprovedList = partner.get_offer_whitelist
    currentApprovedList.delete(params[:offerid])
    partner.offer_whitelist = currentApprovedList.to_a.join(';')
    partner.save!
    redirect_to pubwhitelist_path
    
  end
end
