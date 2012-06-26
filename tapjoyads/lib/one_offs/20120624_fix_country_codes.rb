class OneOffs

  def self.fix_country_codes
    Offer.find_by_sql("select * from offers where countries like '%FX%'").each do |offer|
      offer.countries = offer.get_countries.delete 'FX'
      offer.save!
    end
  end

end
