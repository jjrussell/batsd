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

  def self.country_code_to_mobile_country_codes
    return @country_code_to_mobile_country_codes if defined?(@country_code_to_mobile_country_codes)
    @country_code_to_mobile_country_codes = {
      "AD" => "213",
      "AE" => "424,430,431",
      "AF" => "412",
      "AG" => "344",
      "AI" => "365",
      "AL" => "276",
      "AM" => "283",
      "AO" => "631",
      "AR" => "722",
      "AS" => "544",
      "AT" => "232",
      "AU" => "505",
      "AW" => "363",
      "AZ" => "400",
      "BA" => "218",
      "BB" => "342",
      "BD" => "470",
      "BE" => "206",
      "BF" => "613",
      "BG" => "284",
      "BH" => "426",
      "BI" => "642",
      "BJ" => "616",
      "BM" => "350",
      "BN" => "528",
      "BO" => "736",
      "BR" => "724",
      "BS" => "364",
      "BT" => "402",
      "BW" => "652",
      "BY" => "257",
      "BZ" => "702",
      "CA" => "302",
      "CD" => "630",
      "CF" => "623",
      "CG" => "629",
      "CH" => "228",
      "CI" => "612",
      "CK" => "548",
      "CL" => "730",
      "CM" => "624",
      "CN" => "460,461",
      "CO" => "732",
      "CR" => "712",
      "CU" => "368",
      "CV" => "625",
      "CW" => "362",
      "CY" => "280",
      "CZ" => "230",
      "DE" => "262",
      "DJ" => "638",
      "DK" => "238",
      "DM" => "366",
      "DO" => "370",
      "DZ" => "603",
      "EC" => "740",
      "EE" => "248",
      "EG" => "602",
      "ER" => "657",
      "ES" => "214",
      "ET" => "636",
      "FI" => "244",
      "FJ" => "542",
      "FK" => "750",
      "FM" => "550",
      "FO" => "288",
      "FR" => "208",
      "GA" => "628",
      "GB" => "234,235",
      "GD" => "352",
      "GE" => "282",
      "GF" => "742",
      "GH" => "620",
      "GI" => "266",
      "GL" => "290",
      "GM" => "607",
      "GN" => "611",
      "GP" => "340",
      "GQ" => "627",
      "GR" => "202",
      "GT" => "704",
      "GU" => "535",
      "GW" => "632",
      "GY" => "738",
      "HK" => "454",
      "HN" => "708",
      "HR" => "219",
      "HT" => "372",
      "HU" => "216",
      "ID" => "510",
      "IE" => "272",
      "IL" => "425",
      "IN" => "404,405,406",
      "IQ" => "418",
      "IR" => "432",
      "IS" => "274",
      "IT" => "222",
      "JM" => "338",
      "JO" => "416",
      "JP" => "440,441",
      "KE" => "639",
      "KG" => "437",
      "KH" => "456",
      "KI" => "545",
      "KM" => "654",
      "KN" => "356",
      "KP" => "467",
      "KR" => "450",
      "KW" => "419",
      "KY" => "346",
      "KZ" => "401",
      "LA" => "457",
      "LB" => "415",
      "LC" => "358",
      "LI" => "295",
      "LK" => "413",
      "LR" => "618",
      "LS" => "651",
      "LT" => "246",
      "LU" => "270",
      "LV" => "247",
      "LY" => "606",
      "MA" => "604",
      "MC" => "212",
      "MD" => "259",
      "ME" => "297",
      "MG" => "646",
      "MH" => "551",
      "MK" => "294",
      "ML" => "610",
      "MM" => "414",
      "MN" => "428",
      "MO" => "455",
      "MP" => "534",
      "MQ" => "340",
      "MR" => "609",
      "MS" => "354",
      "MT" => "278",
      "MU" => "617",
      "MV" => "472",
      "MW" => "650",
      "MX" => "334",
      "MY" => "502",
      "MZ" => "643",
      "NA" => "649",
      "NC" => "546",
      "NE" => "614",
      "NG" => "621",
      "NI" => "710",
      "NL" => "204",
      "NO" => "242",
      "NP" => "429",
      "NR" => "536",
      "NU" => "555",
      "NZ" => "530",
      "OM" => "422",
      "PA" => "714",
      "PE" => "716",
      "PF" => "547",
      "PG" => "537",
      "PH" => "515",
      "PK" => "410",
      "PL" => "260",
      "PM" => "308",
      "PR" => "330",
      "PS" => "425",
      "PT" => "268",
      "PW" => "552",
      "PY" => "744",
      "QA" => "427",
      "RE" => "647",
      "RO" => "226",
      "RS" => "220",
      "RU" => "250",
      "RW" => "635",
      "SA" => "420",
      "SB" => "540",
      "SC" => "633",
      "SD" => "634",
      "SE" => "240",
      "SG" => "525",
      "SI" => "293",
      "SK" => "231",
      "SL" => "619",
      "SM" => "292",
      "SN" => "608",
      "SO" => "637",
      "SR" => "746",
      "ST" => "626",
      "SV" => "706",
      "SY" => "417",
      "SZ" => "653",
      "TC" => "376",
      "TD" => "622",
      "TG" => "615",
      "TH" => "520",
      "TJ" => "436",
      "TL" => "514",
      "TM" => "438",
      "TN" => "605",
      "TO" => "539",
      "TR" => "286",
      "TT" => "374",
      "TW" => "466",
      "TZ" => "640",
      "UA" => "255",
      "UG" => "641",
      "US" => "310,311,312,313,314,315,316",
      "UY" => "748",
      "UZ" => "434",
      "VA" => "225",
      "VC" => "360",
      "VE" => "734",
      "VG" => "348",
      "VI" => "332",
      "VN" => "452",
      "VU" => "541",
      "WF" => "543",
      "WS" => "549",
      "YE" => "421",
      "ZA" => "655",
      "ZM" => "645",
      "ZW" => "648",
    }
  end

end
