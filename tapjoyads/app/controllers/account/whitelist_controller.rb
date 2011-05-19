class Account::WhitelistController < WebsiteController
  layout 'tabbed'
  current_tab :account

  filter_access_to :all

  def index
    unless current_partner.use_whitelist?
      redirect_to apps_path
    end  
    @whitelisted_offers = current_partner.get_offer_whitelist
    @offers = Offer.enabled_offers.by_name(params[:name]).by_device(params[:device])
    @status_to_show = params[:status]
  end
  
  def enable
    unless current_partner.use_whitelist?
      redirect_to apps_path
    end
    current_partner.add_to_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end
  
  def disable
    unless current_partner.use_whitelist?
      redirect_to apps_path
    end
    current_partner.remove_from_whitelist(params[:id])
    current_partner.save!
    redirect_to account_whitelist_index_path
  end
end
