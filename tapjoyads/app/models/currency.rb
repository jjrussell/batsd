class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :app
  
  validates_presence_of :app
  validates_numericality_of :conversion_rate, :initial_balance, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :offers_money_share, :installs_money_share, :greater_than_or_equal_to => 0
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :in => [ true, false ]
end
