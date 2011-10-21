class CachedApp
  
  attr_accessor :id, :name, :description, :primary_category, :user_rating, :price, :url
  
  def initialize(offer, description = nil)
    self.id = offer.id
    self.name = offer.name
    self.price = offer.price
    self.description = description
    
    if offer.app_offer?
      self.url = offer.item.info_url
      self.primary_category = offer.item.primary_category
      self.user_rating = offer.item.user_rating
    else
      self.url = offer.url
      self.primary_category = nil
      self.user_rating = nil
    end
      
  end
  
  def icon_url
    Offer.get_icon_url(:source => :cloudfront, :icon_id => Offer.hashed_icon_id(self.id))
  end

end
