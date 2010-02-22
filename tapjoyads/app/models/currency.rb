class Currency < SimpledbResource
  include RewardHelper
  
  self.domain_name = 'currency'
  
  self.sdb_attr :initial_balance, :type => :int, :default_value => 0
  self.sdb_attr :only_free_apps, :type => :bool
  self.sdb_attr :disabled_apps
  self.sdb_attr :disabled_offers
  self.sdb_attr :currency_name
  self.sdb_attr :conversion_rate, :type => :int
  self.sdb_attr :callback_url
  self.sdb_attr :cs_callback_url
  self.sdb_attr :show_rating_offer, :type => :bool
  self.sdb_attr :secret_key
  self.sdb_attr :virtual_good_currency, :type => :bool
  self.sdb_attr :installs_money_share, :type => :float
  self.sdb_attr :beta_devices, :type => :json, :default_value => []
  
  def get_app_currency_reward(app)
    return calculate_install_payouts(:currency => self, :advertiser_app => app)[:currency_reward]
  end
  
  def get_offer_currency_reward(offer)
    return calculate_offer_payouts(:currency => self, :offer_amount => offer.get('amount'))[:currency_reward]
  end
end