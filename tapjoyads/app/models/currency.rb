class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedHelper
  
  belongs_to :app
  
  validates_presence_of :app
  validates_numericality_of :conversion_rate, :initial_balance, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :offers_money_share, :installs_money_share, :greater_than_or_equal_to => 0
  validates_numericality_of :max_age_rating, :allow_nil => true, :only_integer => true
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :in => [ true, false ]
  
  after_save :update_memcached
  
  def self.find_in_cache(app_id)
    Currency.new.get_from_cache_and_save("mysql.currency.#{app_id}") { Currency.find_by_app_id(app_id) }
  end
  
  def get_reward_amount(offer)
    if offer.item_type == 'RatingOffer' || offer.item_type == 'OfferpalOffer'
      publisher_amount = offer.payment * offers_money_share
    elsif offer.partner_id == app.partner_id
      publisher_amount = offer.payment
    else
      publisher_amount = offer.payment * installs_money_share
    end
    
    [publisher_amount.to_i * conversion_rate / 100.0, 1.0].max.to_i
  end
  
  def get_disabled_offer_ids
    Set.new(disabled_offers.split(';'))
  end
  
  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end
  
private
  
  def update_memcached
    save_to_cache("mysql.currency.#{app_id}", self)
  end
  
end
