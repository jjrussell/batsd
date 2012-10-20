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
      "OC" => "Oceana",
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

  # TODO: Namespace this in a UnitedStatesOfAmerica class?
  class State

    ALL = [
      "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware",
      "District Of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
      "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
      "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
      "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon",
      "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah",
      "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ]

    NAME_TO_CODE = {
      'Alabama'              => 'AL',
      'Alaska'               => 'AK',
      'Arizona'              => 'AZ',
      'Arkansas'             => 'AR',
      'California'           => 'CA',
      'Colorado'             => 'CO',
      'Connecticut'          => 'CT',
      'Delaware'             => 'DE',
      'District Of Columbia' => 'DC',
      'Florida'              => 'FL',
      'Georgia'              => 'GA',
      'Hawaii'               => 'HI',
      'Idaho'                => 'ID',
      'Illinois'             => 'IL',
      'Indiana'              => 'IN',
      'Iowa'                 => 'IA',
      'Kansas'               => 'KS',
      'Kentucky'             => 'KY',
      'Louisiana'            => 'LA',
      'Maine'                => 'ME',
      'Maryland'             => 'MD',
      'Massachusetts'        => 'MA',
      'Michigan'             => 'MI',
      'Minnesota'            => 'MN',
      'Mississippi'          => 'MS',
      'Missouri'             => 'MO',
      'Montana'              => 'MT',
      'Nebraska'             => 'NE',
      'Nevada'               => 'NV',
      'New Hampshire'        => 'NH',
      'New Jersey'           => 'NJ',
      'New Mexico'           => 'NM',
      'New York'             => 'NY',
      'North Carolina'       => 'NC',
      'North Dakota'         => 'ND',
      'Ohio'                 => 'OH',
      'Oklahoma'             => 'OK',
      'Oregon'               => 'OR',
      'Pennsylvania'         => 'PA',
      'Rhode Island'         => 'RI',
      'South Carolina'       => 'SC',
      'South Dakota'         => 'SD',
      'Tennessee'            => 'TN',
      'Texas'                => 'TX',
      'Utah'                 => 'UT',
      'Vermont'              => 'VT',
      'Virginia'             => 'VA',
      'Washington'           => 'WA',
      'West Virginia'        => 'WV',
      'Wisconsin'            => 'WI',
      'Wyoming'              => 'WY'
    }

    CODE_TO_NAME = NAME_TO_CODE.invert
    PAIRS = NAME_TO_CODE.map { |state, code| [state, code] }
  end
end

include Earth;
