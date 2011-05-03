class AppGroup < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :apps
  
  validates_presence_of :name
  
  WEIGHT_COLUMNS = [ :conversion_rate, :bid, :price, :avg_revenue, :random, :over_threshold ]
  
  def weights    
    weights = {}
    WEIGHT_COLUMNS.each do |weight|
      weights[weight] = eval(weight.to_s)
    end
    weights
  end
end
