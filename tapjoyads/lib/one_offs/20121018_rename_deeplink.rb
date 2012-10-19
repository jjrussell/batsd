class OneOffs
  def self.rename_deeplinks
    # currently there are around 12,000 deeplink offers
    Deeplink.find_each do |deeplink|
      deeplink.name = "Check out more ways to enjoy the apps you love at Tapjoy.com!"
      deeplink.save!
    end

    Offer.where(["item_type = ? and name like 'Earn % in %' ", 'DeeplinkOffer']).find_each do |offer|
      offer.name = "Check out more ways to enjoy the apps you love at Tapjoy.com!"
      offer.save!
    end
  end
end
