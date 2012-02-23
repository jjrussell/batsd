class Stats < SimpledbResource

  self.domain_name = 'stats'

  self.sdb_attr :values, :type => :json, :default_value => {}
  self.sdb_attr :virtual_goods, :type => :json, :default_value => {}
  self.sdb_attr :countries, :type => :json, :default_value => {}

  attr_reader :parsed_values, :parsed_virtual_goods, :parsed_countries

  CONVERSION_STATS  = Conversion::STAT_TO_REWARD_TYPE_MAP.keys
  WEB_REQUEST_STATS = WebRequest::STAT_TO_PATH_MAP.keys
  SPECIAL_STATS     = [ 'virtual_goods', 'countries', 'ranks' ]
  STAT_TYPES        = CONVERSION_STATS + WEB_REQUEST_STATS + SPECIAL_STATS

  COUNTRY_CODES = {
      'US' => 'United States',
      'AR' => 'Argentina',
      'AU' => 'Australia',
      'BY' => 'Belarus',
      'BE' => 'Belgium',
      'BR' => 'Brazil',
      'BG' => 'Bulgaria',
      'CA' => 'Canada',
      'CL' => 'Chile',
      'CN' => 'China',
      'CO' => 'Columbia',
      'CR' => 'Costa Rica',
      'HR' => 'Croatia (Hrvatska)',
      'CZ' => 'Czech Republic',
      'DK' => 'Denmark',
      'DE' => 'Germany',
      'SV' => 'El Salvador',
      'ES' => 'Spain',
      'FI' => 'Finland',
      'FR' => 'France',
      'GR' => 'Greece',
      'GT' => 'Guatemala',
      'HK' => 'Hong Kong',
      'HU' => 'Hungary',
      'IN' => 'India',
      'ID' => 'Indonesia',
      'IE' => 'Ireland',
      'IL' => 'Israel',
      'IT' => 'Italy',
      'JP' => 'Japan',
      'KR' => 'South Korea',
      'KW' => 'Kuwait',
      'LB' => 'Lebanon',
      'LU' => 'Luxembourg',
      'MY' => 'Malaysia',
      'MX' => 'Mexico',
      'NL' => 'Netherlands',
      'NZ' => 'New Zealand',
      'NO' => 'Norway',
      'AT' => 'Austria',
      'PK' => 'Pakistan',
      'PA' => 'Panama',
      'PE' => 'Peru',
      'PH' => 'Philippines',
      'PL' => 'Poland',
      'PT' => 'Portugal',
      'QA' => 'Qatar',
      'RO' => 'Romania',
      'RU' => 'Russia',
      'SA' => 'Saudi Arabia',
      'RS' => 'Serbia',
      'CH' => 'Switzerland',
      'SG' => 'Singapore',
      'SK' => 'Slovak Republic',
      'SI' => 'Slovenia',
      'ZA' => 'South Africa',
      'LK' => 'Sri Lanka',
      'SE' => 'Sweden',
      'TW' => 'Taiwan',
      'TH' => 'Thailand',
      'TR' => 'Turkey',
      'UA' => 'Ukraine',
      'AE' => 'United Arab Emirates',
      'GB' => 'United Kingdom',
      'VE' => 'Venezuela',
      'VN' => 'Vietnam',
  }

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end

  def after_initialize
    @parsed_values = values
    @parsed_virtual_goods = virtual_goods
    @parsed_countries = countries
  end

  ##
  # Gets the hourly stats for a stat type.
  # stat_name_or_path: The stat to get, a string, or an array representing the path.
  def get_hourly_count(stat_name_or_path)
    get_counts_object(stat_name_or_path, 24)
  end

  def get_daily_count(stat_name_or_path)
    get_counts_object(stat_name_or_path, 31)
  end

  ##
  # Gets the memcache key for a specific stat_name_or_path and app_id. The key will be unique for the hour.
  def self.get_memcache_count_key(stat_name_or_path, app_id, time)
    stat_name_string = Array(stat_name_or_path).join(',')
    "stats.#{stat_name_string}.#{app_id}.#{(time.to_i / 1.hour).to_i}"
  end

  ##
  # Updates the count of a stat for a given hour.
  # stat_name_or_path: Which stat to update
  # hour: The 0-based hour of the day.
  # count: The value to set.
  def update_stat_for_hour(stat_name_or_path, hour, count)
    update_stat(stat_name_or_path, hour, count, 24)
  end

  ##
  # Updates the count of a stat for a given day.
  # stat_name_or_path: Which stat to update
  # day: The 0-based day of the month.
  # count: The value to set.
  def update_stat_for_day(stat_name_or_path, day, count)
    update_stat(stat_name_or_path, day, count, 31)
  end

  def update_stat(stat_name_or_path, ordinal, count, length)
    counts = get_counts_object(stat_name_or_path, length)
    counts[ordinal] = count
  end

  ##
  # Populates the daily_stat_row from an hourly_stat_row.
  # hourly_stat_row: Source of data.
  # day: The 0-based day of the month in which to populate.
  def populate_daily_from_hourly(hourly_stat_row, day)
    hourly_stat_row.parsed_values.each do |key, value|
      count = value.sum
      update_stat_for_day(key, day, count)
    end

    hourly_stat_row.parsed_virtual_goods.each do |key, value|
      stat_path = ['virtual_goods', key]
      count = value.sum
      update_stat_for_day(stat_path, day, count)
    end

    hourly_stat_row.parsed_countries.each do |key, value|
      stat_path = ['countries', key]
      count = value.compact.sum
      update_stat_for_day(stat_path, day, count)
    end
  end

  ##
  # Returns a triplet, the prefix, the date, and the app_id or campaign_id (if any), as parsed from the row key.
  def parse_key
    parts = @key.split('.')
    date_parts = parts[1].split('-')
    date = Time.utc(date_parts[0], date_parts[1], date_parts[2])

    return parts[0], date, parts[2]
  end

  def save(options = {})
    strip_defaults(@parsed_values)
    strip_defaults(@parsed_virtual_goods)
    strip_defaults(@parsed_countries)

    self.values = @parsed_values if self.values != @parsed_values
    self.virtual_goods = @parsed_virtual_goods if self.virtual_goods != @parsed_virtual_goods
    self.countries = @parsed_countries if self.countries != @parsed_countries

    super({ :write_to_memcache => true }.merge(options)) if changed?
  end

  def hourly?
    @key.split('.')[1].length == 10
  end

  def update_daily_stat
    raise "This method should be used only on hourly stats" unless hourly?
    prefix, date, offer_id = parse_key
    daily_key = "#{prefix}.#{date.strftime('%Y-%m')}"
    daily_key << ".#{offer_id}" unless offer_id.blank?
    daily_stat = Stats.new(:key => daily_key, :load_from_memcache => false, :consistent => true)
    daily_stat.populate_daily_from_hourly(self, date.day - 1)
    daily_stat.save
  end

  private

  def strip_defaults(hash)
    hash.each do |key, value|
      hash.delete(key) if value.uniq == [0]
    end
  end

  def get_counts_object(stat_name_or_path, length)
    if stat_name_or_path == 'virtual_goods'
      return @parsed_virtual_goods
    elsif stat_name_or_path.is_a?(Array) && stat_name_or_path.first == 'virtual_goods'
      obj = @parsed_virtual_goods
    elsif stat_name_or_path == 'countries'
      return @parsed_countries
    elsif stat_name_or_path.is_a?(Array) && stat_name_or_path.first == 'countries'
      obj = @parsed_countries
    else
      obj = @parsed_values
    end

    key = Array(stat_name_or_path).last

    obj[key] = Array.new(length, 0) if obj[key].nil?
    obj[key]
  end
end
