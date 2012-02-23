class Countries

  CONTINENT_CODES = %w(NA SA EU AS OC AF)

  CONTINENT_CODE_TO_NAME = {
    "AS" => "Asia",
    "EU" => "Europe",
    "SA" => "South America",
    "AF" => "Africa",
    "AN" => "Antarctica",
    "OC" => "Oceana",
    "NA" => "North America"
  }

  def self.country_code_to_name
    return @@country_code_to_name if defined?(@@country_code_to_name)

    @@country_code_to_name = {}
    GeoIP::CountryCode.each_with_index do |code, i|
      @@country_code_to_name[code] = GeoIP::CountryName[i]
    end
    @@country_code_to_name
  end

  def self.country_names(usa_first=true)
    rejects = Set.new(CONTINENT_CODE_TO_NAME.values)
    rejects << 'United States' if usa_first
    countries = GeoIP::CountryName.reject{|name| rejects.include?(name)}.sort
    countries.unshift('United States') if usa_first
    countries
  end

  def self.contintent_code_to_country_codes
    @@contintent_code_to_country_codes ||= get_contintent_code_to_country_codes
  end

  def self.get_contintent_code_to_country_codes
    @@contintent_code_to_country_codes = {}
    GeoIP::CountryContinent.each_with_index do |continent_code, i|
      next if GeoIP::CountryCode[i] == 'KP'
      @@contintent_code_to_country_codes[continent_code] ||= []
      @@contintent_code_to_country_codes[continent_code] << GeoIP::CountryCode[i]
    end

    CONTINENT_CODES.each do |continent_code|
      @@contintent_code_to_country_codes[continent_code].sort! do |c1, c2|
        country_code_to_name[c1] <=> country_code_to_name[c2]
      end
    end

    @@contintent_code_to_country_codes
  end

end
