class Appstats

  attr_accessor :app_key, :stats, :granularity, :start_time, :end_time, :x_labels, :intervals

  def initialize(app_key, options = {})
    @granularity = options.delete(:granularity) { :hourly }

    @now = @granularity == :hourly ? Time.zone.now : Time.now.utc
    @start_time = options.delete(:start_time) { @now.beginning_of_hour - 23.hours }
    @end_time = options.delete(:end_time) { @start_time + 24.hours }

    @stat_types = options.delete(:stat_types) { Stats::STAT_TYPES }
    @include_labels = options.delete(:include_labels) { false }
    @stat_prefix = options.delete(:stat_prefix) { 'app' }
    @platform = @stat_prefix =~ /\w+-(\w+)/ ? $1 : 'all'
    cache_hours = options.delete(:cache_hours) { 3 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    @app_key = app_key
    @stat_rows = {}

    @stats = {}

    @stat_types.each do |stat_type|
      next if stat_type == 'ranks'
      @stats[stat_type] = if @granularity == :hourly
        get_hourly_stats(stat_type, @start_time.utc, @end_time.utc, cache_hours)
      else
        get_daily_stats(stat_type, @start_time.utc, @end_time.utc, cache_hours)
      end
    end
    if @stat_types.include?('ranks')
      if @stat_prefix == 'app'
        @stats['ranks'] = if @granularity == :hourly
          S3Stats::Ranks.hourly_over_time_range(@app_key, @start_time.utc, @end_time.utc)
        else
          S3Stats::Ranks.daily_over_time_range(@app_key, @start_time.utc, @end_time.utc)
        end
      else
        @stats['ranks'] = {}
      end
    end

    # cvr
    if @stats['paid_clicks'] and @stats['paid_installs']
      @stats['cvr'] = []
      @stats['paid_clicks'].length.times do |i|
        if @stats['paid_clicks'][i] == 0
          @stats['cvr'][i] = 0
        else
          @stats['cvr'][i] = "%.2f" % (@stats['paid_installs'][i].to_f / @stats['paid_clicks'][i])
        end
      end
    end

    # rewards
    if @stats['published_installs'] and @stats['offers']
      @stats['rewards'] = []
      @stats['published_installs'].length.times do |i|
        @stats['rewards'][i] = @stats['published_installs'][i] + @stats['offers'][i] - @stats['display_conversions'][i]
      end
    end

    # rewards_opened
    if @stats['offers_opened']
      @stats['rewards_opened'] = []
      @stats['offers_opened'].length.times do |i|
        @stats['rewards_opened'][i] = @stats['offers_opened'][i] - @stats['display_clicks'][i]
      end
    end

    # rewards_revenue
    if @stats['installs_revenue'] and @stats['offers_revenue']
      @stats['rewards_revenue'] = []
      @stats['installs_revenue'].length.times do |i|
        @stats['rewards_revenue'][i] = @stats['installs_revenue'][i] + @stats['offers_revenue'][i]
      end
    end

    # rewards_ctr
    if @stats['offerwall_views'] and @stats['rewards_opened']
      @stats['rewards_ctr'] = []
      @stats['offerwall_views'].length.times do |i|
        if @stats['offerwall_views'][i] == 0
          @stats['rewards_ctr'][i] = 0
        else
          @stats['rewards_ctr'][i] = @stats['rewards_opened'][i].to_f / @stats['offerwall_views'][i].to_f
        end
      end
    end

    # rewards_cvr
    if @stats['rewards_opened'] and @stats['rewards']
      @stats['rewards_cvr'] = []
      @stats['rewards_opened'].length.times do |i|
        if @stats['rewards_opened'][i] == 0
          @stats['rewards_cvr'][i] = 0
        else
          @stats['rewards_cvr'][i] = "%.2f" % (@stats['rewards'][i].to_f / @stats['rewards_opened'][i])
        end
      end
    end

    # offerwall_ecpm
    if @stats['offerwall_views'] and @stats['rewards_revenue']
      @stats['offerwall_ecpm'] = []
      @stats['offerwall_views'].length.times do |i|
        if @stats['offerwall_views'][i] == 0
          @stats['offerwall_ecpm'][i] = 0
        else
          @stats['offerwall_ecpm'][i] = @stats['rewards_revenue'][i].to_f / (@stats['offerwall_views'][i] / 1000.0)
        end
      end
    end

    # featured_ctr
    if @stats['featured_offers_shown'] and @stats['featured_offers_opened']
      @stats['featured_ctr'] = []
      @stats['featured_offers_shown'].length.times do |i|
        if @stats['featured_offers_shown'][i] == 0
          @stats['featured_ctr'][i] = 0
        else
          @stats['featured_ctr'][i] = @stats['featured_offers_opened'][i].to_f / @stats['featured_offers_shown'][i].to_f
        end
      end
    end

    # featured_cvr
    if @stats['featured_offers_opened'] and @stats['featured_published_offers']
      @stats['featured_cvr'] = []
      @stats['featured_offers_opened'].length.times do |i|
        if @stats['featured_offers_opened'][i] == 0
          @stats['featured_cvr'][i] = 0
        else
          @stats['featured_cvr'][i] = @stats['featured_published_offers'][i].to_f / @stats['featured_offers_opened'][i].to_f
        end
      end
    end

    # featured_fill_rate
    if @stats['featured_offers_requested'] and @stats['featured_offers_shown']
      @stats['featured_fill_rate'] = []
      @stats['featured_offers_requested'].length.times do |i|
        if @stats['featured_offers_requested'][i] == 0
          @stats['featured_fill_rate'][i] = 0
        else
          @stats['featured_fill_rate'][i] = @stats['featured_offers_shown'][i].to_f / @stats['featured_offers_requested'][i].to_f
        end
      end
    end

    # featured_ecpm
    if @stats['featured_offers_shown'] and @stats['featured_revenue']
      @stats['featured_ecpm'] = []
      @stats['featured_offers_shown'].length.times do |i|
        if @stats['featured_offers_shown'][i] == 0
          @stats['featured_ecpm'][i] = 0
        else
          @stats['featured_ecpm'][i] = @stats['featured_revenue'][i].to_f / (@stats['featured_offers_shown'][i] / 1000.0)
        end
      end
    end

    # display_fill_rate
    if @stats['display_ads_requested'] and @stats['display_ads_shown']
      @stats['display_fill_rate'] = []
      @stats['display_ads_requested'].length.times do |i|
        if @stats['display_ads_requested'][i] == 0
          @stats['display_fill_rate'][i] = 0
        else
          @stats['display_fill_rate'][i] = @stats['display_ads_shown'][i].to_f / @stats['display_ads_requested'][i].to_f
        end
      end
    end

    # display_ctr
    if @stats['display_ads_shown'] and @stats['display_clicks']
      @stats['display_ctr'] = []
      @stats['display_ads_shown'].length.times do |i|
        if @stats['display_ads_shown'][i] == 0
          @stats['display_ctr'][i] = 0
        else
          @stats['display_ctr'][i] = @stats['display_clicks'][i].to_f / @stats['display_ads_shown'][i].to_f
        end
      end
    end

    # display_cvr
    if @stats['display_clicks'] and @stats['display_conversions']
      @stats['display_cvr'] = []
      @stats['display_clicks'].length.times do |i|
        if @stats['display_clicks'][i] == 0
          @stats['display_cvr'][i] = 0
        else
          @stats['display_cvr'][i] = @stats['display_conversions'][i].to_f / @stats['display_clicks'][i].to_f
        end
      end
    end

    # display_ecpm
    if @stats['display_ads_shown'] and @stats['display_revenue']
      @stats['display_ecpm'] = []
      @stats['display_ads_shown'].length.times do |i|
        if @stats['display_ads_shown'][i] == 0
          @stats['display_ecpm'][i] = 0
        else
          @stats['display_ecpm'][i] = @stats['display_revenue'][i].to_f / (@stats['display_ads_shown'][i] / 1000.0)
        end
      end
    end

    # non_display_revenue
    if @stats['rewards_revenue'] and @stats['featured_revenue']
      @stats['non_display_revenue'] = []
      @stats['rewards_revenue'].length.times do |i|
        @stats['non_display_revenue'][i] = @stats['rewards_revenue'][i] + @stats['featured_revenue'][i]
      end
    end

    # total_revenue
    if @stats['rewards_revenue'] and @stats['featured_revenue'] and @stats['display_revenue']
      @stats['total_revenue'] = []
      @stats['rewards_revenue'].length.times do |i|
        @stats['total_revenue'][i] = @stats['rewards_revenue'][i] + @stats['featured_revenue'][i] + @stats['display_revenue'][i]
      end
    end

    # arpdau
    if @granularity == :daily and @stats['daily_active_users'] and @stats['total_revenue']
      @stats['arpdau'] = []
      @stats['daily_active_users'].length.times do |i|
        if @stats['daily_active_users'][i] == 0
          @stats['arpdau'][i] = 0
        else
          @stats['arpdau'][i] = @stats['total_revenue'][i].to_f / @stats['daily_active_users'][i]
        end
      end
    end

    get_labels_and_intervals if @include_labels
  end

  def graph_data(options = {})
    offer = options.delete(:offer)
    admin = options.delete(:admin) { false }

    if offer && offer.item_type == 'App'
      conversion_name = 'Installs'
    else
      conversion_name = 'Conversions'
    end

    is_android = offer.present? && (/android/i =~ offer.get_platform)
    data = {
      :connect_data => connect_data,
      :rewarded_installs_plus_spend_data => rewarded_installs_plus_spend_data(conversion_name),
      :rewarded_installs_plus_rank_data => rewarded_installs_plus_rank_data(conversion_name, is_android),
      :revenue_data => revenue_data(admin),
      :offerwall_data => offerwall_data,
      :featured_offers_data => featured_offers_data,
      :display_ads_data => display_ads_data,
      :ads_data => ads_data,

      :granularity => @granularity,
      :date => @start_time.to_date.to_s(:mdy),
      :end_date => @end_time.to_date.to_s(:mdy),
      :platform => @platform
    }

    if get_virtual_good_partitions(offer).size > 0
      data[:virtual_goods_data] = virtual_goods_data(offer)
    end

    if @granularity == :daily
      data[:connect_data][:main][:names] << 'DAUs'
      data[:connect_data][:main][:data] << @stats['daily_active_users']
      data[:connect_data][:main][:stringData] << @stats['daily_active_users'].map { |i| NumberHelper.number_with_delimiter(i) }
      data[:connect_data][:main][:totals] << '-'
      data[:connect_data][:right] = {
        :unitPrefix => '$',
        :decimals => 2,
        :names => [ 'ARPDAU' ],
        :data => [ @stats['arpdau'].map { |i| i / 100.0 } ],
        :stringData => [ @stats['arpdau'].map { |i| NumberHelper.number_to_currency(i / 100.0, :precision => 4) } ],
        :totals => [ '-' ],
      }
    end

    if admin
      # country breakdowns
      data[:rewarded_installs_plus_spend_data][:partition_names]    = spend_partition_names
      data[:rewarded_installs_plus_spend_data][:partition_left]     = paid_installs_partitions
      data[:rewarded_installs_plus_spend_data][:partition_right]    = installs_spend_partitions
      data[:rewarded_installs_plus_spend_data][:partition_title]    = 'Country (Country data is not real-time)'
      data[:rewarded_installs_plus_spend_data][:partition_fallback] = 'Country data does not exist for this app during this time frame'
      data[:rewarded_installs_plus_spend_data][:partition_default]  = 'United States'
      # jailbroken data
      data[:rewarded_installs_plus_spend_data][:main][:names]      << "Jb #{conversion_name}"
      data[:rewarded_installs_plus_spend_data][:main][:data]       << @stats['jailbroken_installs']
      data[:rewarded_installs_plus_spend_data][:main][:stringData] << @stats['jailbroken_installs'].map { |i| NumberHelper.number_with_delimiter(i) }
      data[:rewarded_installs_plus_spend_data][:main][:totals]     << NumberHelper.number_with_delimiter(@stats['jailbroken_installs'].sum)
    end

    data
  end

  def to_csv
    data =  "start_time,end_time,paid_clicks,paid_installs,new_users,paid_cvr,spend,itunes_rank_overall_free_united_states,"
    data += "offerwall_views,published_offer_clicks,published_offers_completed,published_cvr,offerwall_revenue,offerwall_ecpm,display_ads_revenue,display_ads_ecpm,featured_revenue,featured_ecpm"
    data += ",daily_active_users,arpdau" if @granularity == :daily
    data = [data]
    get_labels_and_intervals unless @intervals.present?

    @stats['paid_clicks'].length.times do |i|
      time_format = (@granularity == :daily) ? :mdy_ampm_utc : :mdy_ampm

      line = [
        @intervals[i].to_s(time_format),
        @intervals[i + 1].to_s(time_format),
        @stats['paid_clicks'][i],
        @stats['paid_installs'][i],
        @stats['new_users'][i],
        @stats['cvr'][i],
        NumberHelper.number_to_currency(@stats['installs_spend'][i] / -100.0, :delimiter => ''),
        (Array(@stats['ranks']['overall.free.united_states'])[i] || '-'),
        @stats['offerwall_views'][i],
        @stats['rewards_opened'][i],
        @stats['rewards'][i],
        @stats['rewards_cvr'][i],
        NumberHelper.number_to_currency(@stats['rewards_revenue'][i] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@stats['offerwall_ecpm'][i] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@stats['display_revenue'][i] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@stats['display_ecpm'][i] / 100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@stats['featured_revenue'][i] /100.0, :delimiter => ''),
        NumberHelper.number_to_currency(@stats['featured_ecpm'][i] /100.0, :delimiter => ''),
      ]

      if @granularity == :daily
        line << @stats['daily_active_users'][i]
        line << NumberHelper.number_to_currency(@stats['arpdau'][i] / 100.0, :delimiter => '')
      end
      data << line.join(',')
    end

    data
  end

  def self.parse_dates(start_time_string, end_time_string, granularity_string)
    start_time, end_time = get_times(start_time_string, end_time_string)

    if granularity_string == 'daily' || end_time - start_time >= 7.days
      granularity = :daily
    else
      granularity = :hourly
      start_time, end_time = get_times(start_time_string, end_time_string, false)
    end

    if (end_time - start_time < 1.day) && granularity == :daily
      start_time = start_time.beginning_of_day
      end_time = end_time.end_of_day
    end

    return start_time, end_time, granularity
  end

private

  def self.get_times(start_time_string, end_time_string, use_utc = true)
    now = use_utc ? Time.now.utc : Time.zone.now
    if start_time_string.blank?
      start_time = now.beginning_of_hour - 23.hours
    else
      start_time = (use_utc ? start_time_string.to_time : Time.zone.parse(start_time_string)).beginning_of_day
      start_time = now.beginning_of_hour - 23.hours if start_time > now
    end

    if end_time_string.blank?
      end_time = start_time + 24.hours
    else
      end_time = (use_utc ? end_time_string.to_time : Time.zone.parse(end_time_string)).end_of_day
      end_time = now if end_time <= start_time || end_time > now
    end

    [start_time, end_time]
  end

  ##
  # Returns the hourly stats for stat_name.
  # If stat_name corresponds to a single stat, then the returned object will be an array with each
  # value representing a single hour's worth of stats.
  # If stat_name corresponds to a set of stats (e.g. 'ranks'), then the returned object will be a
  # hash, with the values of the hash being arrays of hourly stats.
  def get_hourly_stats(stat_name, start_time, end_time, cache_hours)
    time = start_time
    date = nil
    hourly_stats_over_range = []
    hourly_stats = []
    size = ((end_time - start_time) / 1.hour).ceil
    index = 0
    while time < end_time
      if date != time.strftime('%Y-%m-%d')
        date = time.strftime('%Y-%m-%d')
        stat = load_stat_row(date)
        populate_hourly_stats_from_memcached(stat, stat_name, cache_hours)
        hourly_stats = stat.get_hourly_count(stat_name)
      end

      if hourly_stats.is_a?(Hash)
        hourly_stats_over_range = {} if hourly_stats_over_range.blank?
        hourly_stats.each do |key, values|
          value = values[time.hour]
          unless value == 0
            hourly_stats_over_range[key] ||= Array.new(size, 0)
            hourly_stats_over_range[key][index] = value
          end
        end
      else
        hourly_stats_over_range[index] = hourly_stats[time.hour]
      end

      time = time + 1.hour
      index += 1
    end
    return hourly_stats_over_range
  end

  ##
  # Returns the daily stats for stat_name, an array or a hash. See #get_hourly_stats.
  def get_daily_stats(stat_name, start_time, end_time, cache_hours)
    time = start_time
    daily_stats_over_range = []
    daily_stats = []
    date = nil
    size = ((end_time - start_time) / 1.day).ceil
    index = 0
    while time + 1.hour < end_time
      if date != time.strftime('%Y-%m')
        date = time.strftime('%Y-%m')
        stat = load_stat_row(date)
        daily_stats = stat.get_daily_count(stat_name)
      end

      if time + 38.hours > @now
        hourly_stat = load_stat_row("#{date}-#{time.strftime("%d")}")
        populate_hourly_stats_from_memcached(hourly_stat, stat_name, cache_hours)
        stat.populate_daily_from_hourly(hourly_stat, time.day - 1)
        daily_stats = stat.get_daily_count(stat_name)
      end

      if daily_stats.is_a?(Hash)
        daily_stats_over_range = {} if daily_stats_over_range.blank?
        daily_stats.each do |key, values|
          value = values[time.day - 1]
          unless value == 0
            daily_stats_over_range[key] ||= Array.new(size, 0)
            daily_stats_over_range[key][index] = value
          end
        end
      else
        daily_stats_over_range[index] = daily_stats[time.day - 1]
      end

      time = time + 1.day
      index += 1
    end
    return daily_stats_over_range
  end

  def load_stat_row(date_string)
    key = "#{@stat_prefix}.#{date_string}"
    key << ".#{@app_key}" if @app_key

    @stat_rows[key] ||= Stats.new(:key => key)
  end

  def populate_hourly_stats_from_memcached(stat_row, stat_name, cache_hours)
    return if cache_hours == 0

    prefix, date, app_id = stat_row.parse_key
    if stat_name == 'virtual_goods'
      vg_keys = Mc.get("virtual_good_list.keys.#{app_id}") || []
      vg_keys.each do |vg_key|
        counts = stat_row.get_hourly_count(['virtual_goods', vg_key])
        24.times do |i|
          time = date + i.hours
          if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
            counts[i] = Mc.get_count(Stats.get_memcache_count_key(['virtual_goods', vg_key], app_id, time))
          end
        end
      end
    elsif stat_name == 'countries'
      counts_hash = stat_row.get_hourly_count('countries')
      counts_hash.each do |key, counts|
        24.times do |i|
          time = date + i.hours
          if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
            counts[i] = nil
          end
        end
      end
    else
      counts = stat_row.get_hourly_count(stat_name)
      if counts.is_a?(Array)
        24.times do |i|
          time = date + i.hours
          if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
            counts[i] = Mc.get_count(Stats.get_memcache_count_key(stat_name, app_id, time))
          end
        end
      end
    end
  end

  def get_labels_and_intervals
    @intervals = []
    @x_labels = []
    this_time = @start_time

    while this_time < @end_time
      @intervals << this_time

      if @granularity == :daily
        @x_labels << this_time.strftime('%m-%d')
      else
        @x_labels << this_time.to_s(:time)
      end

      this_time += (@granularity == :daily ? 1.day : 1.hour)
    end

    if @x_labels.size > 30
      skip_every = @x_labels.size / 30
      @x_labels.size.times do |i|
        if i % (skip_every + 1) != 0
          @x_labels[i] = nil
        end
      end
    end

    @intervals << this_time
  end

  def formatted_intervals
    return @formatted_intervals if defined?(@formatted_intervals)
    if @granularity == :daily
      @formatted_intervals = @intervals.map { |time| time.to_s(:pub) + " UTC" }
    else
      @formatted_intervals = @intervals.map { |time| time.to_s(:pub_ampm) }
    end
  end

  def spend_partitions
    return @spend_partitions if defined?(@spend_partitions)
    @spend_partitions = {}
    @spend_partitions[:installs_spend] = {}
    @spend_partitions[:paid_installs] = {}

    keys = @stats['countries'].keys.sort

    keys.each do |key|

      key_parts = key.split('.')
      key_parts[1] == 'other' ? country = 'Other' : country = Stats::COUNTRY_CODES[key_parts[1]]
      partitions_key = key_parts[0].to_sym
      raise "Unknown attribute #{partitions_key}" unless [:installs_spend, :paid_installs].include? partitions_key
      parts = @stats['countries'][key]
      @spend_partitions[partitions_key]

      @spend_partitions[partitions_key][country] ||= {}
      @spend_partitions[partitions_key][country][:names] ||= []
      @spend_partitions[partitions_key][country][:data] ||= []
      @spend_partitions[partitions_key][country][:stringData] ||= []
      @spend_partitions[partitions_key][country][:totals] ||= []
      title = (key_parts[0] == "installs_spend" ? "Spend" : "Paid Installs")
      @spend_partitions[partitions_key][country][:names] << "#{title} (#{key_parts[1]})"

      if partitions_key == :installs_spend
        @spend_partitions[partitions_key][country][:data] << parts.map { |i| i == nil ? nil : i / -100.0 }
        @spend_partitions[partitions_key][country][:totals] << NumberHelper.number_to_currency(parts.compact.sum / -100.0)
        @spend_partitions[partitions_key][country][:stringData] << parts.map { |i| i == nil ? '-' : NumberHelper.number_to_currency(i / -100.0) }
      elsif partitions_key == :paid_installs
        @spend_partitions[partitions_key][country][:data] << parts
        @spend_partitions[partitions_key][country][:stringData] << parts.map { |i| NumberHelper.number_with_delimiter(i) }
        @spend_partitions[partitions_key][country][:totals] << NumberHelper.number_with_delimiter(parts.compact.sum)
      end
    end

    @spend_partitions
  end

  def installs_spend_partitions
    return @installs_spend_partitions if defined?(@installs_spend_partitions)
    @installs_spend_partitions = get_spend_partition(:installs_spend)
  end

  def paid_installs_partitions
    return @paid_installs_partitions if defined?(@paid_installs_partitions)
    @paid_installs_partitions = get_spend_partition(:paid_installs)
  end

  def get_spend_partition(key)
    return nil if spend_partition_names.empty?
    partitions = []
    spend_partition_names.each do |name|
      partitions << spend_partitions[key][name] unless spend_partitions[key][name].nil?
    end
    partitions.empty? ? nil : partitions
  end

  def spend_partition_names
    @spend_partition_names ||= spend_partitions[:installs_spend].keys.sort do |k1, k2|
      k1.gsub('Other', 'zzzz') <=> k2.gsub('Other', 'zzzz')
    end
  end

  def get_rank_partitions
    return @rank_partitions if defined?(@rank_partitions)
    @rank_partitions = {}

    keys = @stats['ranks'].keys.sort do |key1, key2|
      key1.gsub(/^overall/, '1') <=> key2.gsub(/^overall/, '1')
    end

    keys.each do |key|
      key_parts = key.split('.')
      country = "#{key_parts[2].titleize} (#{key_parts[1].titleize.gsub('Ipad', 'iPad')})"
      ranks = @stats['ranks'][key]

      @rank_partitions[country] ||= {}
      @rank_partitions[country][:yMax] = 200
      @rank_partitions[country][:names] ||= []
      @rank_partitions[country][:data] ||= []
      @rank_partitions[country][:totals] ||= []

      @rank_partitions[country][:names] << "#{key_parts[0].titleize}"
      @rank_partitions[country][:data] << ranks
      @rank_partitions[country][:totals] << (ranks.compact.last.ordinalize rescue '-')
    end

    @rank_partitions
  end

  def get_rank_partition_names
    get_rank_partitions.keys.sort
  end

  def get_rank_partition_values
    values = []
    get_rank_partition_names.each do |name|
      values << get_rank_partitions[name]
    end
    values
  end

  def get_virtual_good_partitions(offer)
    return {} unless offer
    return @virtual_good_partitions if @virtual_good_partitions.present?
    @virtual_good_partitions = {}

    virtual_goods = offer.virtual_goods.sort

    virtual_goods.each_with_index do |vg, i|
      mod = i % 5
      upper = [i - mod + 5, virtual_goods.size].min
      group = "#{i - mod + 1} - #{upper}"

      @virtual_good_partitions[group] ||= {}
      @virtual_good_partitions[group][:names] ||= []
      @virtual_good_partitions[group][:longNames] ||= []
      @virtual_good_partitions[group][:data] ||= []
      @virtual_good_partitions[group][:stringData] ||= []
      @virtual_good_partitions[group][:totals] ||= []

      vg_name = vg.name[0, 13].strip
      vg_data = @stats['virtual_goods'][vg.key] || Array.new(@stats['vg_purchases'].size, 0)

      @virtual_good_partitions[group][:names] << vg_name
      @virtual_good_partitions[group][:longNames] << vg.name
      @virtual_good_partitions[group][:data] << vg_data
      @virtual_good_partitions[group][:stringData] << vg_data.map { |i| NumberHelper.number_with_delimiter(i) }
      @virtual_good_partitions[group][:totals] << (NumberHelper.number_with_delimiter(@stats['virtual_goods'][vg.key].sum) rescue 0)
    end

    @virtual_good_partitions
  end

  def get_virtual_good_partition_names(offer)
    get_virtual_good_partitions(offer).keys.sort do |k1, k2|
      k1.split[0].to_i <=> k2.split[0].to_i
    end
  end

  def get_virtual_good_partition_values(offer)
    get_virtual_good_partition_names(offer).map do |name|
      get_virtual_good_partitions(offer)[name]
    end
  end

  def connect_data
    {
      :name => 'Sessions',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Sessions', 'New Users' ],
        :data => [ @stats['logins'], @stats['new_users'] ],
        :stringData => [ @stats['logins'].map { |i| NumberHelper.number_with_delimiter(i) }, @stats['new_users'].map { |i| NumberHelper.number_with_delimiter(i) } ],
        :totals => [ NumberHelper.number_with_delimiter(@stats['logins'].sum), NumberHelper.number_with_delimiter(@stats['new_users'].sum) ],
      },
    }
  end

  def rewarded_installs_plus_spend_data(conversion_name)
    {
      :name => "Paid #{conversion_name} + Advertising spend",
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ "Total Paid #{conversion_name}", 'Total Clicks' ],
        :data => [ @stats['paid_installs'], @stats['paid_clicks'] ],
        :stringData => [ @stats['paid_installs'].map { |i| NumberHelper.number_with_delimiter(i) }, @stats['paid_clicks'].map { |i| NumberHelper.number_with_delimiter(i) } ],
        :totals => [ NumberHelper.number_with_delimiter(@stats['paid_installs'].sum), NumberHelper.number_with_delimiter(@stats['paid_clicks'].sum) ],
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Total Spend' ],
        :data => [ @stats['installs_spend'].map { |i| i / -100.0 } ],
        :stringData => [ @stats['installs_spend'].map { |i| NumberHelper.number_to_currency(i / -100.0) } ],
        :totals => [ NumberHelper.number_to_currency(@stats['installs_spend'].sum / -100.0) ],
      },
      :extra => {
        :names => [ 'Conversion rate' ],
        :data => [ @stats['cvr'].map { |cvr| "%.0f%" % (cvr.to_f * 100.0) } ],
        :totals => [ @stats['paid_clicks'].sum > 0 ? ("%.1f%" % (@stats['paid_installs'].sum.to_f / @stats['paid_clicks'].sum * 100.0)) : '-' ],
      },
    }
  end

  def rewarded_installs_plus_rank_data(conversion_name, is_android)
    {
      :name => "Paid #{conversion_name} + Ranks",
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ "Total Paid #{conversion_name}" ],
        :data => [ @stats['paid_installs'] ],
        :stringData => [ @stats['paid_installs'].map { |i| NumberHelper.number_with_delimiter(i) } ],
        :totals => [ NumberHelper.number_with_delimiter(@stats['paid_installs'].sum) ],
      },
      :partition_names => get_rank_partition_names,
      :partition_right => get_rank_partition_values,
      :partition_title => is_android ? "Language" : "Country",
      :partition_fallback => 'This app is not in the top charts in any categories for the selected date range.',
      :partition_default => is_android ? "English" : 'United States',
    }
  end

  def revenue_data(admin)
    {
      :name => admin ? "Publisher Revenue" : "Revenue",
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :unitPrefix => '$',
        :names => [ 'Total revenue', 'Offerwall revenue', 'Featured offer revenue', 'Display ad revenue' ],
        :data => [
          @stats['total_revenue'].map { |i| i / 100.0 },
          @stats['rewards_revenue'].map { |i| i / 100.0 },
          @stats['featured_revenue'].map { |i| i / 100.0 },
          @stats['display_revenue'].map { |i| i / 100.0 },
        ],
        :stringData => [
          @stats['total_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['rewards_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['featured_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['display_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
        ],
        :totals => [
          NumberHelper.number_to_currency(@stats['total_revenue'].sum / 100.0),
          NumberHelper.number_to_currency(@stats['rewards_revenue'].sum / 100.0),
          NumberHelper.number_to_currency(@stats['featured_revenue'].sum / 100.0),
          NumberHelper.number_to_currency(@stats['display_revenue'].sum / 100.0),
        ],
      },
    }
  end

  def offerwall_data
    {
      :name => 'Offerwall',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Offerwall views', 'Clicks', 'Conversions' ],
        :data => [
          @stats['offerwall_views'], @stats['rewards_opened'], @stats['rewards'],
        ],
        :stringData => [
          @stats['offerwall_views'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['rewards_opened'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['rewards'].map { |i| NumberHelper.number_with_delimiter(i) },
        ],
        :totals => [
          NumberHelper.number_with_delimiter(@stats['offerwall_views'].sum),
          NumberHelper.number_with_delimiter(@stats['rewards_opened'].sum),
          NumberHelper.number_with_delimiter(@stats['rewards'].sum),
        ],
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue', 'eCPM' ],
        :data => [
          @stats['rewards_revenue'].map { |i| i / 100.0 },
          @stats['offerwall_ecpm'].map { |i| i / 100.0 },
        ],
        :stringData => [
          @stats['rewards_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['offerwall_ecpm'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
        ],
        :totals => [
          NumberHelper.number_to_currency(@stats['rewards_revenue'].sum / 100.0),
          @stats['offerwall_views'].sum > 0 ? NumberHelper.number_to_currency(@stats['rewards_revenue'].sum.to_f / (@stats['offerwall_views'].sum / 1000.0) / 100.0) : '$0.00',
        ],
      },
      :extra => {
        :names => [ 'CTR', 'CVR' ],
        :data => [
          @stats['rewards_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
          @stats['rewards_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
        ],
        :totals => [
          @stats['offerwall_views'].sum > 0 ? ("%.1f%" % (@stats['rewards_opened'].sum.to_f / @stats['offerwall_views'].sum * 100.0)) : '-',
          @stats['rewards_opened'].sum > 0 ? ("%.1f%" % (@stats['rewards'].sum.to_f / @stats['rewards_opened'].sum * 100.0)) : '-',
        ],
      },
    }
  end

  def featured_offers_data
    {
      :name => 'Featured offers',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Offers requested', 'Offers shown', 'Clicks', 'Conversions' ],
        :data => [
          @stats['featured_offers_requested'],
          @stats['featured_offers_shown'],
          @stats['featured_offers_opened'],
          @stats['featured_published_offers'],
        ],
        :stringData => [
          @stats['featured_offers_requested'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['featured_offers_shown'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['featured_offers_opened'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['featured_published_offers'].map { |i| NumberHelper.number_with_delimiter(i) },
        ],
        :totals => [
          NumberHelper.number_with_delimiter(@stats['featured_offers_requested'].sum),
          NumberHelper.number_with_delimiter(@stats['featured_offers_shown'].sum),
          NumberHelper.number_with_delimiter(@stats['featured_offers_opened'].sum),
          NumberHelper.number_with_delimiter(@stats['featured_published_offers'].sum),
        ],
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue', 'eCPM' ],
        :data => [
          @stats['featured_revenue'].map { |i| i / 100.0 },
          @stats['featured_ecpm'].map { |i| i / 100.0 },
        ],
        :stringData => [
          @stats['featured_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['featured_ecpm'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
        ],
        :totals => [
          NumberHelper.number_to_currency(@stats['featured_revenue'].sum / 100.0),
          @stats['featured_offers_shown'].sum > 0 ? NumberHelper.number_to_currency(@stats['featured_revenue'].sum.to_f / (@stats['featured_offers_shown'].sum / 1000.0) / 100.0) : '$0.00',
        ],
      },
      :extra => {
        :names => [ 'Fill rate', 'CTR', 'CVR' ],
        :data => [
          @stats['featured_fill_rate'].map { |r| "%.0f%" % (r.to_f * 100.0) },
          @stats['featured_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
          @stats['featured_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
        ],
        :totals => [
          @stats['featured_offers_requested'].sum > 0 ? ("%.1f%" % (@stats['featured_offers_shown'].sum.to_f / @stats['featured_offers_requested'].sum * 100.0)) : '-',
          @stats['featured_offers_shown'].sum > 0 ? ("%.1f%" % (@stats['featured_offers_opened'].sum.to_f / @stats['featured_offers_shown'].sum * 100.0)) : '-',
          @stats['featured_offers_opened'].sum > 0 ? ("%.1f%" % (@stats['featured_published_offers'].sum.to_f / @stats['featured_offers_opened'].sum * 100.0)) : '-',
        ],
      },
    }
  end

  def display_ads_data
    {
      :name => 'Display ads',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Ads requested', 'Ads shown', 'Clicks', 'Conversions' ],
        :data => [
          @stats['display_ads_requested'],
          @stats['display_ads_shown'],
          @stats['display_clicks'],
          @stats['display_conversions'],
        ],
        :stringData => [
          @stats['display_ads_requested'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['display_ads_shown'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['display_clicks'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['display_conversions'].map { |i| NumberHelper.number_with_delimiter(i) },
        ],
        :totals => [
          NumberHelper.number_with_delimiter(@stats['display_ads_requested'].sum),
          NumberHelper.number_with_delimiter(@stats['display_ads_shown'].sum),
          NumberHelper.number_with_delimiter(@stats['display_clicks'].sum),
          NumberHelper.number_with_delimiter(@stats['display_conversions'].sum),
        ],
      },
      :right => {
        :unitPrefix => '$',
        :names => [ 'Revenue', 'eCPM' ],
        :data => [
          @stats['display_revenue'].map { |i| i / 100.0 },
          @stats['display_ecpm'].map { |i| i / 100.0 } ],
        :stringData => [
          @stats['display_revenue'].map { |i| NumberHelper.number_to_currency(i / 100.0) },
          @stats['display_ecpm'].map { |i| NumberHelper.number_to_currency(i / 100.0) } ],
        :totals => [
          NumberHelper.number_to_currency(@stats['display_revenue'].sum / 100.0),
          @stats['display_ads_shown'].sum > 0 ? NumberHelper.number_to_currency(@stats['display_revenue'].sum.to_f / (@stats['display_ads_shown'].sum / 1000.0) / 100.0) : '$0.00',
        ],
      },
      :extra => {
        :names => [ 'Fill rate', 'CTR', 'CVR' ],
        :data => [
          @stats['display_fill_rate'].map { |r| "%.0f%" % (r.to_f * 100.0) },
          @stats['display_ctr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
          @stats['display_cvr'].map { |r| "%.0f%" % (r.to_f * 100.0) },
        ],
        :totals => [
          @stats['display_ads_requested'].sum > 0 ? ("%.1f%" % (@stats['display_ads_shown'].sum.to_f / @stats['display_ads_requested'].sum * 100.0)) : '-',
          @stats['display_ads_shown'].sum > 0 ? ("%.1f%" % (@stats['display_clicks'].sum.to_f / @stats['display_ads_shown'].sum * 100.0)) : '-',
          @stats['display_clicks'].sum > 0 ? ("%.1f%" % (@stats['display_conversions'].sum.to_f / @stats['display_clicks'].sum * 100.0)) : '-' ],
      },
    }
  end

  def ads_data
    {
      :name => 'Ad impressions',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Ad impressions' ],
        :data => [ @stats['hourly_impressions'] ],
        :stringData => [
          @stats['hourly_impressions'].map { |i| NumberHelper.number_with_delimiter(i) },
        ],
        :totals => [ NumberHelper.number_with_delimiter(@stats['hourly_impressions'].sum) ],
      },
    }
  end

  def virtual_goods_data(offer)
    {
      :name => 'Virtual good purchases',
      :intervals => formatted_intervals,
      :xLabels => @x_labels,
      :main => {
        :names => [ 'Store views', 'Total purchases' ],
        :data => [ @stats['vg_store_views'], @stats['vg_purchases'] ],
        :stringData => [
          @stats['vg_store_views'].map { |i| NumberHelper.number_with_delimiter(i) },
          @stats['vg_purchases'].map { |i| NumberHelper.number_with_delimiter(i) } ],
        :totals => [
          NumberHelper.number_with_delimiter(@stats['vg_store_views'].sum),
          NumberHelper.number_with_delimiter(@stats['vg_purchases'].sum),
        ],
      },
      :partition_names => get_virtual_good_partition_names(offer),
      :partition_right => get_virtual_good_partition_values(offer),
      :partition_title => 'Virtual goods',
      :partition_fallback => '',
    }
  end
end
