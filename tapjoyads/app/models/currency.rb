class Currency < SimpledbResource
  include RewardHelper
  
  self.domain_name = 'currency'
  
  def get_currency_reward(app)
    calculate_install_payouts(:currency => self, :advertiser_app => app)[:currency_reward]
  end
end