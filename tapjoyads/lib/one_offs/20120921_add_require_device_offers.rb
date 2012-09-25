class OneOffs
  def self.add_require_device_offers
    UDID_REQUIRED_OFFERS = %w(3020a55b-9895-4187-ba9f-8273ea0b26bf f7cc4972-7349-42dd-a696-7fcc9dcc2d03)
    MAC_ADDRESS_REQUIRED_OFFERS = %w(3020a55b-9895-4187-ba9f-8273ea0b26bf)
    Offer.where(:id => UDID_REQUIRED_OFFERS).each { |offer| offer.requires_udid = true and offer.save! if offer }
    Offer.where(:id => MAC_ADDRESS_REQUIRED_OFFERS).each { |offer| offer.requires_mac_address = true and offer.save! if offer }
  end
end
