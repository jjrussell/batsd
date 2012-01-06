class OneOffs

  def self.update_offers_wifi_only_apps
    Offer.find_each(:conditions => "item_type = 'App'") do |o|
      o.wifi_only = true if App.find_by_id(o.item_id).wifi_required?
      o.save! if o.changed?
    end
  end

end
