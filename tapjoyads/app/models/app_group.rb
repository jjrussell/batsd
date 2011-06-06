class AppGroup < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :apps
  
  validates_presence_of :name
  
  WEIGHT_COLUMNS = [ :conversion_rate, :bid, :price, :avg_revenue, :random, :over_threshold ]
  
  def weights
    WEIGHT_COLUMNS.inject({}) { |weights_hash, column| weights_hash[column] = eval(column.to_s); weights_hash }
  end
end
