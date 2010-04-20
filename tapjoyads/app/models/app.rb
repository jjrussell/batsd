class App < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  
  belongs_to :partner
  
  validates_presence_of :partner, :name, :store_id
  
end
