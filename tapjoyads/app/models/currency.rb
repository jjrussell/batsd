class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedHelper
  
  belongs_to :app
  
  validates_presence_of :app
  validates_numericality_of :conversion_rate, :initial_balance, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :offers_money_share, :installs_money_share, :greater_than_or_equal_to => 0
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :in => [ true, false ]
  
  after_save :update_memcached
  
  def self.find_in_cache(app_id)
    Currency.new.get_from_cache_and_save("mysql.currency.#{app_id}") { Currency.find_by_app_id(app_id) }
  end
  
private
  
  def update_memcached
    save_to_cache("mysql.currency.#{app_id}", self)
  end
  
end
