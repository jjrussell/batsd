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

  MOBILE_COUNTRY_CODE_TO_COUNTRY_CODE = {
    "213" => "AD",
    "424" => "AE",
    "430" => "AE",
    "431" => "AE",
    "412" => "AF",
    "344" => "AG",
    "365" => "AI",
    "276" => "AL",
    "283" => "AM",
    "631" => "AO",
    "722" => "AR",
    "544" => "AS",
    "232" => "AT",
    "505" => "AU",
    "363" => "AW",
    "400" => "AZ",
    "218" => "BA",
    "342" => "BB",
    "470" => "BD",
    "206" => "BE",
    "613" => "BF",
    "284" => "BG",
    "426" => "BH",
    "642" => "BI",
    "616" => "BJ",
    "350" => "BM",
    "528" => "BN",
    "736" => "BO",
    "724" => "BR",
    "364" => "BS",
    "402" => "BT",
    "652" => "BW",
    "257" => "BY",
    "702" => "BZ",
    "302" => "CA",
    "630" => "CD",
    "623" => "CF",
    "629" => "CG",
    "228" => "CH",
    "612" => "CI",
    "548" => "CK",
    "730" => "CL",
    "624" => "CM",
    "460" => "CN",
    "461" => "CN",
    "732" => "CO",
    "712" => "CR",
    "368" => "CU",
    "625" => "CV",
    "362" => "CW",
    "280" => "CY",
    "230" => "CZ",
    "262" => "DE",
    "638" => "DJ",
    "238" => "DK",
    "366" => "DM",
    "370" => "DO",
    "603" => "DZ",
    "740" => "EC",
    "248" => "EE",
    "602" => "EG",
    "657" => "ER",
    "214" => "ES",
    "636" => "ET",
    "244" => "FI",
    "542" => "FJ",
    "750" => "FK",
    "550" => "FM",
    "288" => "FO",
    "208" => "FR",
    "628" => "GA",
    "234" => "GB",
    "235" => "GB",
    "352" => "GD",
    "282" => "GE",
    "742" => "GF",
    "620" => "GH",
    "266" => "GI",
    "290" => "GL",
    "607" => "GM",
    "611" => "GN",
    "340" => "GP",
    "627" => "GQ",
    "202" => "GR",
    "704" => "GT",
    "535" => "GU",
    "632" => "GW",
    "738" => "GY",
    "454" => "HK",
    "708" => "HN",
    "219" => "HR",
    "372" => "HT",
    "216" => "HU",
    "510" => "ID",
    "272" => "IE",
    "425" => "IL",
    "404" => "IN",
    "405" => "IN",
    "406" => "IN",
    "418" => "IQ",
    "432" => "IR",
    "274" => "IS",
    "222" => "IT",
    "338" => "JM",
    "416" => "JO",
    "440" => "JP",
    "441" => "JP",
    "639" => "KE",
    "437" => "KG",
    "456" => "KH",
    "545" => "KI",
    "654" => "KM",
    "356" => "KN",
    "467" => "KP",
    "450" => "KR",
    "419" => "KW",
    "346" => "KY",
    "401" => "KZ",
    "457" => "LA",
    "415" => "LB",
    "358" => "LC",
    "295" => "LI",
    "413" => "LK",
    "618" => "LR",
    "651" => "LS",
    "246" => "LT",
    "270" => "LU",
    "247" => "LV",
    "606" => "LY",
    "604" => "MA",
    "212" => "MC",
    "259" => "MD",
    "297" => "ME",
    "646" => "MG",
    "551" => "MH",
    "294" => "MK",
    "610" => "ML",
    "414" => "MM",
    "428" => "MN",
    "455" => "MO",
    "534" => "MP",
    "340" => "MQ",
    "609" => "MR",
    "354" => "MS",
    "278" => "MT",
    "617" => "MU",
    "472" => "MV",
    "650" => "MW",
    "334" => "MX",
    "502" => "MY",
    "643" => "MZ",
    "649" => "NA",
    "546" => "NC",
    "614" => "NE",
    "621" => "NG",
    "710" => "NI",
    "204" => "NL",
    "242" => "NO",
    "429" => "NP",
    "536" => "NR",
    "555" => "NU",
    "530" => "NZ",
    "422" => "OM",
    "714" => "PA",
    "716" => "PE",
    "547" => "PF",
    "537" => "PG",
    "515" => "PH",
    "410" => "PK",
    "260" => "PL",
    "308" => "PM",
    "330" => "PR",
    "425" => "PS",
    "268" => "PT",
    "552" => "PW",
    "744" => "PY",
    "427" => "QA",
    "647" => "RE",
    "226" => "RO",
    "220" => "RS",
    "250" => "RU",
    "635" => "RW",
    "420" => "SA",
    "540" => "SB",
    "633" => "SC",
    "634" => "SD",
    "240" => "SE",
    "525" => "SG",
    "293" => "SI",
    "231" => "SK",
    "619" => "SL",
    "292" => "SM",
    "608" => "SN",
    "637" => "SO",
    "746" => "SR",
    "626" => "ST",
    "706" => "SV",
    "417" => "SY",
    "653" => "SZ",
    "376" => "TC",
    "622" => "TD",
    "615" => "TG",
    "520" => "TH",
    "436" => "TJ",
    "514" => "TL",
    "438" => "TM",
    "605" => "TN",
    "539" => "TO",
    "286" => "TR",
    "374" => "TT",
    "466" => "TW",
    "640" => "TZ",
    "255" => "UA",
    "641" => "UG",
    "310" => "US",
    "311" => "US",
    "312" => "US",
    "313" => "US",
    "314" => "US",
    "315" => "US",
    "316" => "US",
    "748" => "UY",
    "434" => "UZ",
    "225" => "VA",
    "360" => "VC",
    "734" => "VE",
    "348" => "VG",
    "332" => "VI",
    "452" => "VN",
    "541" => "VU",
    "543" => "WF",
    "549" => "WS",
    "421" => "YE",
    "655" => "ZA",
    "645" => "ZM",
    "648" => "ZW",
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
