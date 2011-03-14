class GlobalStats

  def self.aggregate_hourly_global_stats(date = nil)
    date ||= Time.zone.now - 10.minutes
    global_stat = Stats.new(:key => "global.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_stat.parsed_values.clear
    global_stat.parsed_countries.clear

    Stats.select(:where => "itemName() like 'app.#{date.strftime('%Y-%m-%d')}%'") do |this_stat|
      this_stat.parsed_values.each do |stat, values|
        global_stat.parsed_values[stat] = sum_arrays(global_stat.get_hourly_count(stat), values)
      end

      this_stat.parsed_countries.each do |stat, values|
        global_stat.parsed_countries[stat] = sum_arrays(global_stat.get_hourly_count(['countries', stat]), values)
      end
    end

    global_stat.serial_save
    global_stat
  end

  def self.aggregate_daily_global_stats(date = nil)
    date ||= Time.zone.now
    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  date.beginning_of_day ])
    if num_unverified > 0
      Rails.logger.info "there are #{num_unverified} offers with unverified stats, not aggregating global stats yet"
      return
    end
    yesterday = date.yesterday
    daily_stat = Stats.new(:key => "global.#{yesterday.strftime('%Y-%m')}", :load_from_memcache => false)
    # logins won't be empty if stats have already been aggregated for yesterday
    if daily_stat.get_daily_count('logins')[yesterday.day - 1] == 0
      puts "*" * 80
      hourly_stat = aggregate_hourly_global_stats(yesterday)
      daily_stat.populate_daily_from_hourly(hourly_stat, yesterday.day - 1)
      daily_stat.serial_save
    else
      Rails.logger.info "stats have already been aggregated for yesterday: #{yesterday}"
    end
  end

  def self.sum_arrays(array1, array2)
    array1.zip(array2).map { |pair| pair[0] + pair[1] }
  end

end
