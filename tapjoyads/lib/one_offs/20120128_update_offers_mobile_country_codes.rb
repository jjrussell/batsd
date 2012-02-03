class OneOffs

  def self.update_offers_mobile_country_codes
    Offer.find_each(:conditions => "countries != ''") do |o|
      new_mobile_country_codes = []
      o.get_countries.each do |country_code|
        new_mobile_country_codes << Countries.country_code_to_mobile_country_codes[country_code]
      end
      o.mobile_country_codes = new_mobile_country_codes.to_json
      o.save! if o.changed?
    end
  end

end
