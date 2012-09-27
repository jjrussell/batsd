class OneOffs
  def self.add_require_device_offers
    udid_required = %w(3020a55b-9895-4187-ba9f-8273ea0b26bf f7cc4972-7349-42dd-a696-7fcc9dcc2d03)
    mac_address_required = %w(3020a55b-9895-4187-ba9f-8273ea0b26bf)
    Offer.where(:id => udid_required).each { |offer| offer.requires_udid = true and offer.save! if offer }
    Offer.where(:id => mac_address_required).each { |offer| offer.requires_mac_address = true and offer.save! if offer }
  end
end
