class PubOfferWhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :account

  filter_access_to :all

  def index
    if current_partner.use_whitelist  
      @whitelisted_offers = current_partner.get_offer_whitelist
      offer_name = params[:name]
      if offer_name != nil
        offer_name = '%' + offer_name + "%"
      else
        offer_name = "%"
      end
      platform_to_show = params[:platform]
      if platform_to_show != nil
        platform_to_show = "%" + platform_to_show + "%"
      else
        platform_to_show = "%"
      end
      @offers = Offer.enabled_offers.by_name(offer_name).by_device(platform_to_show)
      @status_to_show = params[:status]
    else
      redirect_to apps_path
    end
  end
  
  def enable
    unless current_partner.use_whitelist
      redirect_to apps_path
    end
    current_partner.add_to_whitelist(params[:offerid])
    current_partner.save!
    redirect_to pubwhitelist_path
  end
  
  def disable
    unless current_partner.use_whitelist
      redirect_to apps_path
    end
    current_partner.remove_from_whitelist(params[:offerid])
    current_partner.save!
    redirect_to pubwhitelist_path
  end
end
