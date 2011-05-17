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
  validates_numericality_of :spend_share, :direct_pay_share, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :max_age_rating, :minimum_featured_bid, :allow_nil => true, :only_integer => true
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :banner_advertiser, :hide_app_installs, :tapjoy_enabled, :in => [ true, false ]
  validates_each :callback_url do |record, attribute, value|
    unless SPECIAL_CALLBACK_URLS.include?(value) || value =~ /^https?:\/\//
      record.errors.add(attribute, 'is not a valid url')
    end
  end
  validates_each :disabled_offers, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using whitelisting") if record.use_whitelist? && value.present?
  end
  
  named_scope :for_ios, :joins => :app, :conditions => "#{App.quoted_table_name}.platform = 'iphone'"
  named_scope :just_app_ids, :select => :app_id, :group => :app_id
  
  before_validation :remove_whitespace_from_attributes
  before_create :set_values_from_partner
  after_save :update_memcached_by_app_id
  after_destroy :clear_memcached_by_app_id
  
  def self.find_all_in_cache_by_app_id(app_id, do_lookup = (Rails.env != 'production'))
    if do_lookup
      Mc.distributed_get_and_put("mysql.app_currencies.#{app_id}") { find_all_by_app_id(app_id, :order => 'ordinal ASC') }
    else
      Mc.distributed_get("mysql.app_currencies.#{app_id}") { [] }
    end
  end
  
  def self.cache_all
    find_each do |c|
      c.send(:update_memcached)
      if c.id == c.app_id
        Mc.distributed_put("mysql.app_currencies.#{c.app_id}", Currency.find_all_by_app_id(c.app_id, :order => 'ordinal ASC'))
      end
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
    elsif offer.direct_pay?
      publisher_amount = offer.payment * direct_pay_share
    else
      publisher_amount = offer.payment * spend_share
    end
    
    if displayer_app.present?
      if displayer_app.id == app_id
        publisher_amount = 0
      else
        publisher_amount *= 0.5
      end
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
      if displayer_app.id == app_id
        get_publisher_amount(offer)
      else
        (offer.payment * displayer_app.display_money_share).to_i
      end
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
  
  def get_offer_whitelist
    Set.new(offer_whitelist.split(';'))
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
    self.spend_share       = partner.rev_share * get_spend_share_ratio
    self.direct_pay_share  = partner.direct_pay_share
    self.offer_whitelist   = partner.offer_whitelist
    self.use_whitelist     = partner.use_whitelist
    self.tapjoy_enabled    = partner.approved_publisher if new_record?
    true
  end
  
  def hide_app_installs_for_version?(app_version)
    hide_app_installs? && minimum_hide_app_installs_version.blank? || app_version.present? && hide_app_installs? && app_version.version_greater_than_or_equal_to?(minimum_hide_app_installs_version)
  end
  
  def cache_offers
    Benchmark.realtime do
      weights = app.group.weights

      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list
      cache_offer_list(offer_list, weights, DEFAULT_OFFER_TYPE, Experiments::EXPERIMENTS[:default], app)

      offer_list = Offer.enabled_offers.featured.for_offer_list + Offer.enabled_offers.nonfeatured.free_apps.for_offer_list
      cache_offer_list(offer_list, weights.merge({ :random => 0 }), FEATURED_OFFER_TYPE, Experiments::EXPERIMENTS[:default], app)
    
      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list.for_display_ads
      cache_offer_list(offer_list, weights, DISPLAY_OFFER_TYPE, Experiments::EXPERIMENTS[:default], app)
    end
  end
  
  def cache_offer_list(offer_list, weights, type, exp)
    stats = Offer.get_offer_rank_statistics(type)
    
    offer_list.each do |offer|
      offer.normalize_stats(stats)
      offer.name = "#{offer.truncated_name}..." if offer.name.length > 40
    end
    
    offer_list.each do |offer|
      offer.calculate_rank_score(weights)
      if (offer.item_type == 'App' || offer.item_type == 'ActionOffer')
        offer_item             = offer.item_type.constantize.find(offer.item_id)
        offer.primary_category = offer_item.primary_category
        offer.user_rating      = offer_item.user_rating
        if offer.item_type == 'ActionOffer'
          action_app = App.find(offer_item.app_id)
          offer.action_offer_name = action_app.name
        end
      end
    end
    
    offer_list.sort! do |o1, o2|
      if o1.featured? && !o2.featured?
        -1
      elsif o2.featured? && !o1.featured?
        1
      else
        o2.rank_score <=> o1.rank_score
      end
    end
    
    offer_list.first.offer_list_length = offer_list.length
  
    offer_groups = []
    group        = 0
    key          = app.present? ? "enabled_offers.#{app.id}.type_#{type}.exp_#{exp}" : "enabled_offers.type_#{type}.exp_#{exp}"
    bucket       = S3.bucket(BucketNames::OFFER_DATA)
    
    offer_list.in_groups_of(GROUP_SIZE) do |offers|
      offers.compact!
      offer_groups << offers
      group += 1
    end
    
    offer_groups.each_with_index do |offers, i|
      Mc.distributed_put("#{key}.#{i}", offers)
    end
  
    if app.present?
      while Mc.distributed_get("#{key}.#{group}")
        Mc.distributed_delete("#{key}.#{group}")
        group += 1
      end
    end
  end
  
private
  
  def update_memcached_by_app_id
    Mc.distributed_put("mysql.app_currencies.#{app_id}", Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC'))
    
    if app_id_changed?
      Mc.distributed_put("mysql.app_currencies.#{app_id_was}", Currency.find_all_by_app_id(app_id_was, :order => 'ordinal ASC'))
    end
  end
  
  def clear_memcached_by_app_id
    Mc.distributed_put("mysql.app_currencies.#{app_id}", Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC'))
  end
  
  def get_spend_share_ratio
    Mc.distributed_get_and_put('currency.spend_share_ratio') do 
      orders = Order.created_since(1.month.ago.to_date)
      
      sum_all_orders = orders.collect(&:amount).sum
      sum_website_orders = orders.select{|o| o.payment_method == 0}.collect(&:amount).sum
      sum_marketing_orders = orders.select{|o| o.payment_method == 2}.collect(&:amount).sum
      
      sum_all_orders == 0 ? 1 : (sum_all_orders - sum_marketing_orders - 0.025 * sum_website_orders) / sum_all_orders
    end
  end
  
  def remove_whitespace_from_attributes
    self.test_devices    = test_devices.gsub(/\s/, '')
    self.disabled_offers = disabled_offers.gsub(/\s/, '')
  end
  
end
