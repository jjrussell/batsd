class Stats < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "stats"

  self.domain_name = 'stats'

  self.sdb_attr :values, :type => :json, :default_value => {}
  self.sdb_attr :virtual_goods, :type => :json, :default_value => {}
  self.sdb_attr :countries, :type => :json, :default_value => {}

  attr_reader :parsed_values, :parsed_virtual_goods, :parsed_countries

  CONVERSION_STATS  = Conversion::STAT_TO_REWARD_TYPE_MAP.keys
  WEB_REQUEST_STATS = WebRequest::STAT_TO_PATH_MAP.keys
  SPECIAL_STATS     = [ 'virtual_goods', 'countries', 'ranks' ]
  STAT_TYPES        = CONVERSION_STATS + WEB_REQUEST_STATS + SPECIAL_STATS

  COUNTRY_CODES = Earth::Country::CODE_TO_NAME

  def initialize(options = {})
    super({ :load_from_memcache => true }.merge(options))
  end

  def after_initialize
    begin
      @parsed_values = values
      @parsed_virtual_goods = virtual_goods
      @parsed_countries = countries
    rescue JSON::ParserError
      fix_bad_json
      @parsed_values = values
      @parsed_virtual_goods = virtual_goods
      @parsed_countries = countries
    end
  end

  def dynamic_domain_name
    if /\w\.(\d\d\d\d)-\d\d/ =~ @key
      return "stats_#{$1}" if $1.to_i > 2012
    end
    'stats'
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

  def self.get_segment_stat(stat, store_name)
    "#{stat}.#{store_name}" if store_name && Stats.segment_by_store?(stat)
  end

  def self.segment_by_store?(stat)
    (WebRequest::STAT_TO_PATH_MAP[stat] && WebRequest::STAT_TO_PATH_MAP[stat][:segment_by_store]) ||
    (Conversion::STAT_TO_REWARD_TYPE_MAP[stat] && Conversion::STAT_TO_REWARD_TYPE_MAP[stat][:segment_by_store])
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
    unless @fixing_bad_json
      strip_defaults(@parsed_values)
      strip_defaults(@parsed_virtual_goods)
      strip_defaults(@parsed_countries)

      changed = false

      if self.values != @parsed_values
        changed = true
        self.values = @parsed_values
      end

      if self.virtual_goods != @parsed_virtual_goods
        changed = true
        self.virtual_goods = @parsed_virtual_goods
      end

      if self.countries != @parsed_countries
        changed = true
        self.countries = @parsed_countries
      end
    end

    super({ :write_to_memcache => true }.merge(options)) if @fixing_bad_json || changed
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

  def fix_bad_json
    @fixing_bad_json = true
    json_attributes = %w(values virtual_goods countries)
    json_attributes.each do |attribute|
      begin
        self.send(attribute.to_sym)
      rescue JSON::ParserError
        multiples = get(attribute).length / 1000
        key = attribute
        multiples.times do
          key += '_'
        end
        self.delete(key)
        self.send(attribute.to_sym)
      end
    end
    save!
  ensure
    @fixing_bad_json = false
  end
end
