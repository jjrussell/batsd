class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  TAPJOY_MANAGED_CALLBACK_URL = 'TAP_POINTS_CURRENCY'
  NO_CALLBACK_URL = 'NO_CALLBACK'
  PLAYDOM_CALLBACK_URL = 'PLAYDOM_DEFINED'
  SPECIAL_CALLBACK_URLS = [ TAPJOY_MANAGED_CALLBACK_URL, NO_CALLBACK_URL, PLAYDOM_CALLBACK_URL ]
  
  belongs_to :app
  belongs_to :partner
  
  validates_presence_of :app, :partner, :name
  validates_numericality_of :conversion_rate, :initial_balance, :ordinal, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :spend_share, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :max_age_rating, :minimum_featured_bid, :allow_nil => true, :only_integer => true
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :in => [ true, false ]
  validates_each :callback_url do |record, attribute, value|
    unless SPECIAL_CALLBACK_URLS.include?(value) || value =~ /^https?:\/\//
      record.errors.add(attribute, 'is not a valid url')
    end
  end
  
  before_create :set_values_from_partner
  after_save :update_memcached_by_app_id
  before_destroy :clear_memcached_by_app_id
  
  def self.find_all_in_cache_by_app_id(app_id, do_lookup = true)
    if do_lookup
      Mc.get_and_put("mysql.app_currencies.#{app_id}") { find_all_by_app_id(app_id, :order => 'ordinal ASC') }
    else
      Mc.get("mysql.app_currencies.#{app_id}")
    end
  end
  
  def get_visual_reward_amount(offer)
    if offer.has_variable_payment?
      orig_payment = offer.payment
      offer.payment = offer.payment_range_low
      visual_amount = "#{get_reward_amount(offer)} - "
      offer.payment = offer.payment_range_high
      visual_amount += "#{get_reward_amount(offer)}"
      offer.payment = orig_payment
    else
      visual_amount = get_reward_amount(offer).to_s
    end
    visual_amount
  end
  
  def get_reward_amount(offer)
    if offer.reward_value.present?
      reward_value = offer.reward_value
    elsif offer.partner_id == partner_id
      reward_value = offer.payment
    else
      reward_value = get_publisher_amount(offer)
    end
    [reward_value * conversion_rate / 100.0, 1.0].max.to_i
  end
  
  def get_publisher_amount(offer, displayer_app = nil)
    if offer.partner_id == partner_id
      publisher_amount = 0
    else
      publisher_amount = offer.payment * spend_share
    end
    
    if displayer_app.present?
      publisher_amount *= 0.5
    end
    
    publisher_amount.to_i
  end
  
  def get_advertiser_amount(offer)
    if offer.partner_id == partner_id
      advertiser_amount = 0
    else
      advertiser_amount = -offer.payment
    end
    advertiser_amount
  end
  
  def get_tapjoy_amount(offer, displayer_app = nil)
    -get_advertiser_amount(offer) - get_publisher_amount(offer, displayer_app) - get_displayer_amount(offer, displayer_app)
  end
  
  def get_displayer_amount(offer, displayer_app = nil)
    if displayer_app.present?
      (offer.payment * displayer_app.display_money_share).to_i
    else
      0
    end
  end

  def get_disabled_offer_ids
    Set.new(disabled_offers.split(';'))
  end
  
  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end
  
  def get_disabled_partners
    Partner.find_all_by_id(disabled_partners.split(';'))
  end
  
  def get_test_device_ids
    Set.new(test_devices.split(';'))
  end

  def tapjoy_managed?
    callback_url == TAPJOY_MANAGED_CALLBACK_URL
  end
  
  def set_values_from_partner
    self.disabled_partners = partner.disabled_partners
    self.spend_share = partner.rev_share * get_spend_share_ratio
  end
  
private
  
  def update_memcached_by_app_id
    Mc.put("mysql.app_currencies.#{app_id}", Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC'))
    
    if app_id_changed?
      Mc.delete("mysql.app_currencies.#{app_id_was}")
    end
  end
  
  def clear_memcached_by_app_id
    Mc.delete("mysql.app_currencies.#{app_id}")
  end
  
  def get_spend_share_ratio
    Mc.get_and_put('currency.spend_share_ratio') do 
      orders = Order.created_since(1.month.ago.to_date)
      
      sum_all_orders = orders.collect(&:amount).sum
      sum_website_orders = orders.select{|o| o.payment_method == 0}.collect(&:amount).sum
      sum_marketing_orders = orders.select{|o| o.payment_method == 2}.collect(&:amount).sum
      
      sum_all_orders == 0 ? 1 : (sum_all_orders - sum_marketing_orders - 0.025 * sum_website_orders) / sum_all_orders
    end
  end
  
end
