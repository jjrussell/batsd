class CachedApp

  attr_accessor :id, :name, :description, :primary_category, :user_rating, :price, :url

  def initialize(offer, description = nil)
    self.id = offer.id
    self.name = offer.name
    self.price = offer.price
    self.description = description

    if offer.item_type == 'App'
      app = App.find_in_cache(offer.item_id)
      self.url = app.info_url
      self.primary_category = app.primary_category
      self.user_rating = app.user_rating
      self.description ||= app.description
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
