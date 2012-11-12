module Earth
  class Country
  private
    def self.country_code_to_name
      return @@country_code_to_name if defined?(@@country_code_to_name)

      @@country_code_to_name = {}
      GeoIP::CountryCode.each_with_index do |code, i|
        @@country_code_to_name[code] = GeoIP::CountryName[i]
      end
      @@country_code_to_name
    end

    def self.country_names(usa_first=true)
      rejects = Set.new(Earth::Continent::ALL)
      rejects << 'United States of America' if usa_first
      countries = GeoIP::CountryName.reject{|name| rejects.include?(name)}.sort
      countries.unshift('United States of America') if usa_first
      countries
    end

  public
    ALL   = country_names
    CODES = GeoIP::CountryCode
    CODE_TO_NAME = country_code_to_name
    NAME_TO_CODE = CODE_TO_NAME.invert
  end
end
