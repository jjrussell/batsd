class CachedApp

  attr_accessor :id, :name, :description, :explanation, :primary_category, :user_rating, :price, :url, :wifi_required, :active_gamer_count

  def initialize(offer, opts = {})
    self.id = offer.id
    self.name = offer.name
    self.price = offer.price
    self.description = opts[:description]
    self.explanation = opts[:explanation]

    if offer.item_type == 'App'
      app = App.find(offer.item_id)
      self.url = Linkshare.add_params(app.info_url)
      self.primary_category = app.primary_category
      self.user_rating = app.user_rating
      self.description ||= app.description
      self.wifi_required = app.wifi_required?
      self.active_gamer_count = app.active_gamer_count
    else
      self.url = offer.url
      self.primary_category = nil
      self.user_rating = nil
    end

  end

  def icon_url
    Offer.get_icon_url(:source => :cloudfront, :icon_id => Offer.hashed_icon_id(self.id), :size => '114')
  end

end
