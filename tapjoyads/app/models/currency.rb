class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  
  TAPJOY_MANAGED_CALLBACK_URL = 'TAP_POINTS_CURRENCY'
  NO_CALLBACK_URL = 'NO_CALLBACK'
  
  belongs_to :app
  belongs_to :partner
  
  validates_presence_of :app, :partner, :name
  validates_numericality_of :conversion_rate, :initial_balance, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :offers_money_share, :installs_money_share, :greater_than_or_equal_to => 0
  validates_numericality_of :max_age_rating, :allow_nil => true, :only_integer => true
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :in => [ true, false ]
  validates_each :callback_url do |record, attribute, value|
    unless value == TAPJOY_MANAGED_CALLBACK_URL || value == NO_CALLBACK || value =~ /^https?:\/\//
      record.errors.add(attribute, 'is not a valid url')
    end
  end
  
  after_save :update_memcached
  before_destroy :clear_memcached
  
  def self.find_in_cache_by_app_id(app_id)
    Mc.get_and_put("mysql.currency.#{app_id}") { Currency.find_by_app_id(app_id) }
  end
  
  def get_reward_amount(offer)
    # TO REMOVE - after Shazam featured campaign is done. NGMoco is way too needy.
    if offer.id == 'a77bffab-fbdd-4b11-a0c4-53cc30b9f8e9' && id == '81195fa3-227f-4dde-936a-989511d0b12d'
      return 5
    end
    [get_publisher_amount(offer) * conversion_rate / 100.0, 1.0].max.to_i
  end
  
  def get_publisher_amount(offer)
    # TO REMOVE - after Shazam featured campaign is done.
    money_share = installs_money_share
    if offer.id == 'a77bffab-fbdd-4b11-a0c4-53cc30b9f8e9' && id == '81195fa3-227f-4dde-936a-989511d0b12d'
      money_share = 0.9
    end
    
    if offer.item_type == 'RatingOffer' || offer.item_type == 'OfferpalOffer'
      publisher_amount = offer.payment * offers_money_share
    elsif offer.partner_id == partner_id
      publisher_amount = offer.payment
    else
      publisher_amount = offer.payment * money_share
    end
    publisher_amount.to_i
  end
  
  def get_advertiser_amount(offer)
    -(offer.actual_payment || offer.payment)
  end
  
  def get_tapjoy_amount(offer)
    tapjoy_amount = -get_advertiser_amount(offer) - get_publisher_amount(offer)
    unless offer.actual_payment.nil?
      tapjoy_amount += offer.actual_payment - offer.payment
    end
    tapjoy_amount
  end
  
  def get_disabled_offer_ids
    Set.new(disabled_offers.split(';'))
  end
  
  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end
  
  def get_test_device_ids
    Set.new(test_devices.split(';'))
  end
  
private
  
  def update_memcached
    Mc.put("mysql.currency.#{app_id}", self)
  end
  
  def clear_memcached
    Mc.delete("mysql.currency.#{app_id}")
  end
  
end
