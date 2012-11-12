module Earth
  class Continent
    # No, Australia is not a continent

    ALL   = ["Africa", "Antarctica", "Asia", "Europe", "North America", "Oceana", "South America"]
    CODES = %w(NA SA EU AS OC AF)

    CODE_TO_NAME = {
      "AF" => "Africa",
      "AN" => "Antarctica",
      "AS" => "Asia",
      "EU" => "Europe",
      "NA" => "North America",
      "OC" => "Oceania",
      "SA" => "South America"
    }
    NAME_TO_CODE = CODE_TO_NAME.invert

    def self.continent_code_to_country_codes
      @@continent_code_to_country_codes ||= get_continent_code_to_country_codes
    end

  # private
    def self.get_continent_code_to_country_codes
      @@continent_code_to_country_codes = {}
      GeoIP::CountryContinent.each_with_index do |continent_code, i|
        code = GeoIP::CountryCode[i]
        next if code == 'KP' || code == 'FX'
        continent_code = 'EU' if code == 'CY'
        @@continent_code_to_country_codes[continent_code] ||= []
        @@continent_code_to_country_codes[continent_code] << code
      end

      CODES.each do |continent_code|
        @@continent_code_to_country_codes[continent_code].sort! do |c1, c2|
            raise c1 unless Country::CODE_TO_NAME[c1]
            raise c2 unless Country::CODE_TO_NAME[c2]
          Country::CODE_TO_NAME[c1] <=> Country::CODE_TO_NAME[c2]
        end
      end

      @@continent_code_to_country_codes
    end
  end
end
