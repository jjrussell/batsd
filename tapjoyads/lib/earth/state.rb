module Earth
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
