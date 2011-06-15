class CurrencyGroup < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :currencies
  
  validates_presence_of :name
  
  WEIGHT_COLUMNS = [ :normal_conversion_rate, :normal_bid, :normal_price, :normal_avg_revenue, :random, :over_threshold, :rank_boost ]
  
  def weights
    WEIGHT_COLUMNS.inject({}) { |weights_hash, column| weights_hash[column] = send(column); weights_hash }
  end
  
end
