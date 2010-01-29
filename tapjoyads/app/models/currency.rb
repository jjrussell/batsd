class Currency < SimpledbResource
  include RewardHelper
  
  self.domain_name = 'currency'
  
  def get_app_currency_reward(app)
    return calculate_install_payouts(:currency => self, :advertiser_app => app)[:currency_reward]
  end
  
  def get_offer_currency_reward(offer)
    return calculate_offer_payouts(:currency => self, :offer_amount => offer.get('amount'))[:currency_reward]
  end
end