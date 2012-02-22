class StatsAggregation

  OFFERS_PER_MESSAGE = 200
  DAILY_STATS_START_HOUR = 3

  def self.check_vertica_accuracy(start_time, end_time)
    appstats_counts = Appstats.new(nil, {
        :stat_prefix => 'global',
        :start_time  => start_time,
        :end_time    => end_time,
        :stat_types  => [ 'featured_offers_requested' ],
        :granularity => :hourly }).stats['featured_offers_requested']
    vertica_counts = {}
    WebRequest.select(
        :select     => "COUNT(hour) AS count, hour",
        :conditions => "path LIKE '%featured_offer_requested%' AND day = '#{start_time.to_s(:yyyy_mm_dd)}'",
        :group      => 'hour').each do |result|
      vertica_counts[result[:hour]] = result[:count]
    end

    appstats_total = appstats_counts.sum
    vertica_total  = vertica_counts.values.sum
    percentage     = vertica_total / appstats_total.to_f
    inaccurate     = percentage < 0.99999 || percentage > 1.00001
    message        = ''

    if inaccurate
      message << "Cannot verify daily stats because Vertica has inaccurate data for #{start_time.to_date}.\n"
      message << "Appstats total: #{appstats_total}\n"
      message << "Vertica total: #{vertica_total}\n"
      message << "Difference: #{appstats_total - vertica_total}\n\n"
      message << "hour, appstats, vertica, diff\n"
      24.times do |i|
        appstats_val = appstats_counts[i]
        vertica_val  = vertica_counts[i] || 0
        message << "#{i}, #{appstats_val}, #{vertica_val}, #{appstats_val - vertica_val}\n"
      end
    end

    [ !inaccurate, message ]
  end

  def self.cache_vertica_stats(start_time, end_time)
    raise "can't wrap over multiple days" if start_time.beginning_of_day != (end_time - 1.second).beginning_of_day

    stats                     = {}
    stat_map                  = WebRequest::STAT_TO_PATH_MAP
    stat_map['virtual_goods'] = { :paths => [ 'purchased_vg' ], :attr_name => 'virtual_good_id', :use_like => false }

    stat_map.each do |stat_name, path_definition|
      stats[stat_name] = {}

      select     = "COUNT(hour) AS count, #{path_definition[:attr_name]}, hour"
      conditions = "#{path_condition(path_definition[:paths], path_definition[:use_like])} AND day = '#{start_time.to_s(:yyyy_mm_dd)}'"
      group      = "#{path_definition[:attr_name]}, hour"
      results    = WebRequest.select(:select => select, :conditions => conditions, :group => group)

      results.each do |result|
        key = result[path_definition[:attr_name].to_sym]
        stats[stat_name][key] ||= Array.new(24, 0)
        stats[stat_name][key][result[:hour]] = result[:count]
      end
    end

    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    bucket.objects[cached_stats_s3_path(start_time, end_time)].write(:data => Marshal.dump(stats))
  end

  def self.cached_vertica_stats(s3_path)
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    Marshal.load(bucket.objects[s3_path].read)
  end

  def self.cached_stats_s3_path(start_time, end_time)
    raise "can't wrap over multiple days" if start_time.beginning_of_day != (end_time - 1.second).beginning_of_day

    "cached_vertica_stats/#{start_time.to_s(:no_spaces)}...#{end_time.to_s(:no_spaces)}"
  end

  def self.path_condition(paths, use_like)
    condition = paths.map { |p| use_like ? "path LIKE '%#{p}%'" : "path = '[#{p}]'" }.join(' OR ')
    "(#{condition})"
  end

  def initialize(offer_ids)
    @offer_ids = offer_ids
    @counts = {}
  end

  def populate_hourly_stats
    now      = Time.zone.now
    end_time = (now - 5.minutes).beginning_of_hour

    Offer.find(@offer_ids).each do |offer|
      start_time = offer.last_stats_aggregation_time || now.beginning_of_day
      stat_rows  = {}

      while start_time < end_time
        date_str = start_time.strftime('%Y-%m-%d')
        stat_rows[date_str] ||= Stats.new(:key => "app.#{date_str}.#{offer.id}", :load_from_memcache => false)

        (Stats::CONVERSION_STATS + Stats::WEB_REQUEST_STATS).each do |stat|
          value = Mc.get_count(Stats.get_memcache_count_key(stat, offer.id, start_time))
          stat_rows[date_str].update_stat_for_hour(stat, start_time.hour, value)
        end

        [ 'paid_installs', 'installs_spend' ].each do |stat|
          next if stat_rows[date_str].get_hourly_count(stat)[start_time.hour] == 0

          (Stats::COUNTRY_CODES.keys + [ 'other' ]).each do |country|
            stat_path = [ 'countries', "#{stat}.#{country}" ]
            value = Mc.get_count(Stats.get_memcache_count_key(stat_path, offer.id, start_time))
            stat_rows[date_str].update_stat_for_hour(stat_path, start_time.hour, value)
          end
        end

        if stat_rows[date_str].get_hourly_count('vg_purchases')[start_time.hour] > 0
          offer.virtual_goods.each do |virtual_good|
            stat_path = [ 'virtual_goods', virtual_good.id ]
            value = Mc.get_count(Stats.get_memcache_count_key(stat_path, offer.id, start_time))
            stat_rows[date_str].update_stat_for_hour(stat_path, start_time.hour, value)
          end
        end

        start_time += 1.hour
      end

      is_active = false
      stat_rows.each_value do |stat_row|
        if stat_row.get_hourly_count('offerwall_views').sum > 0 ||
            stat_row.get_hourly_count('paid_clicks').sum > 0 ||
            stat_row.get_hourly_count('display_ads_requested').sum > 0 ||
            stat_row.get_hourly_count('featured_offers_requested').sum > 0 ||
            (offer.item_type == 'ActionOffer' && stat_row.get_hourly_count('logins').sum > 0)
          is_active = true
        end
        stat_row.serial_save
      end

      offer.active = is_active
      offer.next_stats_aggregation_time = end_time + 65.minutes + rand(50.minutes)
      offer.last_stats_aggregation_time = end_time
      offer.save!
    end
  end

  def verify_hourly_and_populate_daily_stats
    now = Time.zone.now

    Offer.find(@offer_ids).each do |offer|
      start_time = offer.last_daily_stats_aggregation_time || (now - 1.day).beginning_of_day
      end_time   = start_time + 1.day

      next if end_time > now

      hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)

      verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
      verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)

      hourly_stat_row.update_daily_stat
      hourly_stat_row.serial_save

      hourly_ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{start_time.strftime('%Y-%m-%d')}/#{offer.id}", :load_from_memcache => false)
      daily_ranks  = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{start_time.strftime('%Y-%m')}/#{offer.id}", :load_from_memcache => false)
      daily_ranks.populate_daily_from_hourly(hourly_ranks, start_time.day - 1)
      daily_ranks.save

      offer.last_daily_stats_aggregation_time = end_time
      offer.next_daily_stats_aggregation_time = end_time + 1.day + DAILY_STATS_START_HOUR.hours
      offer.save!
    end
  end

  def recount_stats_over_range(start_time, end_time, update_daily = false)
    Offer.find(@offer_ids).each do |offer|
      hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)

      verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
      verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)

      hourly_stat_row.update_daily_stat if update_daily == true
      hourly_stat_row.serial_save
    end
  end

  private

  def verify_web_request_stats_over_range(stat_row, offer, start_time, end_time)
    s3_path = StatsAggregation.cached_stats_s3_path(start_time, end_time)
    @counts[s3_path] ||= StatsAggregation.cached_vertica_stats(s3_path)

    WebRequest::STAT_TO_PATH_MAP.each do |stat_name, path_definition|
      verify_stat_over_range(stat_row, stat_name, offer, start_time, end_time) do |s_time, e_time|
        get_web_request_count(s3_path, stat_name, offer.id, (s_time.hour..(e_time - 1.second).hour))
      end
    end

    if stat_row.get_hourly_count('vg_purchases')[start_time.hour..(end_time - 1.second).hour].sum > 0
      offer.virtual_goods.each do |virtual_good|
        stat_path = [ 'virtual_goods', virtual_good.id ]
        verify_stat_over_range(stat_row, stat_path, offer, start_time, end_time) do |s_time, e_time|
          get_web_request_count(s3_path, 'virtual_goods', virtual_good.id, (s_time.hour..(e_time - 1.second).hour))
        end
      end
    end
  end

  def verify_conversion_stats_over_range(stat_row, offer, start_time, end_time)
    Conversion::STAT_TO_REWARD_TYPE_MAP.each do |stat_name, rtd|
      conditions = [ "#{rtd[:attr_name]} = ? AND reward_type IN (?)", offer.id, rtd[:reward_types] ]
      verify_stat_over_range(stat_row, stat_name, offer, start_time, end_time) do |s_time, e_time|
        Conversion.using_slave_db do
          if rtd[:sum_attr].present?
            Conversion.created_between(s_time, e_time).sum(rtd[:sum_attr], :conditions => conditions)
          else
            Conversion.created_between(s_time, e_time).count(:conditions => conditions)
          end
        end
      end

      next unless stat_name == 'paid_installs' || stat_name == 'installs_spend'

      values_by_country = {}
      (Stats::COUNTRY_CODES.keys + [ 'other' ]).each do |country|
        stat_path = [ 'countries', "#{stat_name}.#{country}" ]
        verify_stat_over_range(stat_row, stat_path, offer, start_time, end_time) do |s_time, e_time|
          key = "#{s_time.to_i}-#{e_time.to_i}"
          values_by_country[key] ||= Conversion.using_slave_db do
            if rtd[:sum_attr].present?
              Conversion.created_between(s_time, e_time).sum(rtd[:sum_attr], :conditions => conditions, :group => :country)
            else
              Conversion.created_between(s_time, e_time).count(:conditions => conditions, :group => :country)
            end
          end
          if country == 'other'
            values_by_country[key].reject { |c, value| Stats::COUNTRY_CODES[c].present? || Stats::COUNTRY_CODES[c.try(:upcase)].present? }.values.sum
          else
            values_by_country[key][country] || values_by_country[key][country.downcase] || 0
          end
        end
      end
    end
  end

  def verify_stat_over_range(stat_row, stat_name_or_path, offer, start_time, end_time)
    value_over_range = yield(start_time, end_time)
    hourly_values    = stat_row.get_hourly_count(stat_name_or_path)

    if end_time - start_time == 1.hour
      hourly_values[start_time.hour] = value_over_range
      return
    end

    range = start_time.hour..(end_time - 1.second).hour
    unless value_over_range == hourly_values[range].sum
      message = "AppStatsVerifyError: Verification of #{stat_name_or_path.inspect} failed for offer: #{offer.name} (#{offer.id}), for range: #{start_time.to_s(:db)} - #{end_time.to_s(:db)}. "
      message << "Value is: #{value_over_range}, hourly values are: #{hourly_values[range].inspect}, difference is: #{value_over_range - hourly_values[range].sum}."
      Rails.logger.info(message)

      time = start_time
      while time < end_time
        hour_value = yield(time, time + 1.hour)
        hourly_values[time.hour] = hour_value
        break if value_over_range == hourly_values[range].sum
        time += 1.hour
      end

      unless value_over_range == hourly_values[range].sum
        raise "Re-counted each hour for #{stat_name_or_path.inspect} and counts do not match the total count for offer: #{offer.name} (#{offer.id}), for range: #{start_time.to_s(:db)} - #{end_time.to_s(:db)}. Value is: #{value_over_range}, hourly sum is: #{hourly_values[range].sum}"
      end
    end
  end

  def get_web_request_count(s3_path, stat_name, key, range)
    (@counts[s3_path][stat_name][key] || [])[range].sum
  end

  def self.aggregate_hourly_group_stats(date = nil, aggregate_daily = false)
    date ||= Time.zone.now - 70.minutes
    global_stat = Stats.new(:key => "global.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_ios_stat = Stats.new(:key => "global-ios.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_android_stat = Stats.new(:key => "global-android.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_joint_stat = Stats.new(:key => "global-joint.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_windows_stat = Stats.new(:key => "global-windows.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)

    global_stats = [global_stat, global_ios_stat, global_android_stat, global_windows_stat, global_joint_stat]

    global_stats.each do |stat|
      stat.parsed_values.clear
      stat.parsed_countries.clear
    end

    Partner.find_each do |partner|
      partner_stat = Stats.new(:key => "partner.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_ios_stat = Stats.new(:key => "partner-ios.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_android_stat = Stats.new(:key => "partner-android.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_joint_stat = Stats.new(:key => "partner-joint.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_windows_stat = Stats.new(:key => "partner-windows.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)

      partner_stats = [partner_stat, partner_ios_stat, partner_android_stat, partner_windows_stat, partner_joint_stat]

      partner_stats.each do |stat|
        stat.parsed_values.clear
        stat.parsed_countries.clear
      end

      partner.offers.find_each do |offer|
        case offer.get_platform
        when 'Android'
          global_platform_stat = global_android_stat
          partner_platform_stat = partner_android_stat
        when 'iOS'
          global_platform_stat = global_ios_stat
          partner_platform_stat = partner_ios_stat
        when 'Windows'
          global_platform_stat = global_windows_stat
          partner_platform_stat = partner_windows_stat
        else
          global_platform_stat = global_joint_stat
          partner_platform_stat = partner_joint_stat
        end

        this_stat = Stats.new(:key => "app.#{date.strftime('%Y-%m-%d')}.#{offer.id}")

        this_stat.parsed_values.each do |stat, values|
          global_stat.parsed_values[stat] = sum_arrays(global_stat.get_hourly_count(stat), values)
          partner_stat.parsed_values[stat] = sum_arrays(partner_stat.get_hourly_count(stat), values)
          global_platform_stat.parsed_values[stat] = sum_arrays(global_platform_stat.get_hourly_count(stat), values)
          partner_platform_stat.parsed_values[stat] = sum_arrays(partner_platform_stat.get_hourly_count(stat), values)
        end

        this_stat.parsed_countries.each do |stat, values|
          global_stat.parsed_countries[stat] = sum_arrays(global_stat.get_hourly_count(['countries', stat]), values)
          partner_stat.parsed_countries[stat] = sum_arrays(partner_stat.get_hourly_count(['countries', stat]), values)
          global_platform_stat.parsed_countries[stat] = sum_arrays(global_platform_stat.get_hourly_count(['countries', stat]), values)
          partner_platform_stat.parsed_countries[stat] = sum_arrays(partner_platform_stat.get_hourly_count(['countries', stat]), values)
        end
      end

      partner_stats.each { |stat| stat.serial_save }
      partner_stats.each { |stat| stat.update_daily_stat } if aggregate_daily
    end

    global_stats.each { |stat| stat.serial_save }
    global_stats.each { |stat| stat.update_daily_stat } if aggregate_daily
  end

  def self.aggregate_daily_group_stats
    date = Time.zone.now
    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  date.beginning_of_day ])
    daily_stat = Stats.new(:key => "global.#{date.yesterday.strftime('%Y-%m')}", :load_from_memcache => false, :consistent => true)
    if num_unverified > 0
      Rails.logger.info "there are #{num_unverified} offers with unverified stats, not aggregating global stats yet"
    elsif daily_stat.get_daily_count('logins')[date.yesterday.day - 1] > 0
      Rails.logger.info "stats have already been aggregated for date: #{date.yesterday}"
    else
      aggregate_hourly_group_stats(date.yesterday, true)
    end
  end

  def self.sum_arrays(array1, array2)
    array1.zip(array2).map { |pair| pair[0] + pair[1] }
  end
end
