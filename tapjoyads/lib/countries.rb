class Countries
  def self.country_code_to_name
    return @@country_code_to_name if defined?(@@country_code_to_name)

    @@country_code_to_name = {}
    GeoIP::CountryCode.each_with_index do |code, i|
      @@country_code_to_name[code] = GeoIP::CountryName[i]
    end
    @@country_code_to_name
  end

  def self.country_names(usa_first=true)
    rejects = Set.new(continent_code_to_name.values)
    rejects << 'United States' if usa_first
    countries = GeoIP::CountryName.reject{|name| rejects.include?(name)}.sort
    countries.unshift('United States') if usa_first
    countries
  end

  def self.continent_code_to_name
    { "AS" => "Asia",
      "EU" => "Europe",
      "SA" => "South America",
      "AF" => "Africa",
      "AN" => "Antarctica",
      "OC" => "Oceana",
      "NA" => "North America" }
  end

  def self.continent_codes
    %w(NA SA EU AS OC AF)
  end

  def self.contintent_code_to_country_codes
    @@contintent_code_to_country_codes ||= get_contintent_code_to_country_codes
  end

  private

  def self.get_contintent_code_to_country_codes
    @@contintent_code_to_country_codes = {}
    GeoIP::CountryContinent.each_with_index do |continent_code, i|
      next if GeoIP::CountryCode[i] == 'KP'
      @@contintent_code_to_country_codes[continent_code] ||= []
      @@contintent_code_to_country_codes[continent_code] << GeoIP::CountryCode[i]
    end

    continent_codes.each do |continent_code|
      @@contintent_code_to_country_codes[continent_code].sort! do |c1, c2|
        country_code_to_name[c1] <=> country_code_to_name[c2]
      end
    end

    @@contintent_code_to_country_codes
  end

end
