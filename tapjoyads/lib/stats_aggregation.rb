class StatsAggregation
  
  def self.recount_stats_over_range(offer_id, start_time, end_time)
    offer = Offer.find(offer_id)
    hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)
    
    verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    
    hourly_stat_row.serial_save
  end
  
  def self.populate_hourly_stats(offer_id)
    offer      = Offer.find(offer_id)
    now        = Time.zone.now
    start_time = offer.last_stats_aggregation_time || now.beginning_of_day
    end_time   = (now - 5.minutes).beginning_of_hour
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
          stat_path = [ 'virtual_goods', virtual_good.key ]
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
  
  def self.verify_hourly_and_populate_daily_stats(offer_id)
    offer      = Offer.find(offer_id)
    now        = Time.zone.now
    start_time = offer.last_daily_stats_aggregation_time || (now - 1.day).beginning_of_day
    end_time   = start_time + 1.day
    
    return if end_time > now
    
    hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)
    
    verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    
    hourly_stat_row.update_daily_stat
    hourly_stat_row.serial_save

    hourly_ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{start_time.strftime('%Y-%m-%d')}/#{offer.id}", :load_from_memcache => false)
    daily_ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{start_time.strftime('%Y-%m')}/#{offer.id}", :load_from_memcache => false)
    daily_ranks.populate_daily_from_hourly(hourly_ranks, start_time.day - 1)
    daily_ranks.save
    
    offer.last_daily_stats_aggregation_time = end_time
    offer.next_daily_stats_aggregation_time = end_time + 1.day + Offer::DAILY_STATS_START_HOUR.hours + rand(Offer::DAILY_STATS_RANGE.hours)
    offer.save!
  end
  
  def self.verify_web_request_stats_over_range(stat_row, offer, start_time, end_time)
    raise "can't wrap over multiple days" if start_time.day != (end_time - 1.second).day
    
    date_string = start_time.strftime("%Y-%m-%d")
    WebRequest::STAT_TO_PATH_MAP.each do |stat_name, path_definition|
      conditions = "#{get_path_condition(path_definition[:paths])} AND #{path_definition[:attr_name]} = '#{offer.id}'"
      verify_stat_over_range(stat_row, stat_name, offer, start_time, end_time) do |s_time, e_time|
        WebRequest.count(:date => date_string, :where => "#{conditions} AND #{get_time_condition(s_time, e_time)}")
      end
    end
    
    if stat_row.get_hourly_count('vg_purchases')[start_time.hour..(end_time - 1.second).hour].sum > 0
      offer.virtual_goods.each do |virtual_good|
        stat_path = [ 'virtual_goods', virtual_good.key ]
        conditions = "path = 'purchased_vg' AND app_id = '#{offer.id}' AND virtual_good_id = '#{virtual_good.key}'"
        verify_stat_over_range(stat_row, stat_path, offer, start_time, end_time) do |s_time, e_time|
          WebRequest.count(:date => date_string, :where => "#{conditions} AND #{get_time_condition(s_time, e_time)}")
        end
      end
    end
  end
  
  def self.verify_conversion_stats_over_range(stat_row, offer, start_time, end_time)
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
          # TO REMOVE: the downcasing after 2011-08-12
          if country == 'other'
            values_by_country[key].reject { |c, value| Stats::COUNTRY_CODES[c].present? || Stats::COUNTRY_CODES[c.try(:upcase)].present? }.values.sum
          else
            values_by_country[key][country] || values_by_country[key][country.downcase] || 0
          end
        end
      end
    end
  end
  
  def self.verify_stat_over_range(stat_row, stat_name_or_path, offer, start_time, end_time)
    value_over_range = yield(start_time, end_time)
    hourly_values = stat_row.get_hourly_count(stat_name_or_path)
    
    if end_time - start_time == 1.hour
      hourly_values[start_time.hour] = value_over_range
      return
    end
    
    if value_over_range != hourly_values[start_time.hour..(end_time - 1.second).hour].sum
      message = "Verification of #{stat_name_or_path.inspect} failed for offer: #{offer.name} (#{offer.id}), for range: #{start_time.to_s(:db)} - #{end_time.to_s(:db)}. Value is: #{value_over_range}, hourly values are: #{hourly_values[start_time.hour..(end_time - 1.second).hour].inspect}"
      Notifier.alert_new_relic(AppStatsVerifyError, message)
      
      time = start_time
      while time < end_time
        hour_value = yield(time, time + 1.hour)
        hourly_values[time.hour] = hour_value
        break if value_over_range == hourly_values[start_time.hour..(end_time - 1.second).hour].sum
        time += 1.hour
      end
      
      if value_over_range != hourly_values[start_time.hour..(end_time - 1.second).hour].sum
        raise "Re-counted each hour for #{stat_name_or_path.inspect} and counts do not match the total count for offer: #{offer.name} (#{offer.id}), for range: #{start_time.to_s(:db)} - #{end_time.to_s(:db)}. Value is: #{value_over_range}, hourly sum is: #{hourly_values[start_time.hour..(end_time - 1.second).hour].sum}"
      end
    end
  end
  
  def self.get_time_condition(start_time, end_time)
    "time >= '#{start_time.to_f}' AND time < '#{end_time.to_f}'"
  end
  
  def self.get_path_condition(paths)
    path_condition = paths.map { |p| "path = '#{p}'" }.join(' OR ')
    "(#{path_condition})"
  end
  
  def self.aggregate_hourly_group_stats(date = nil, aggregate_daily = false)
    date ||= Time.zone.now - 70.minutes
    global_stat = Stats.new(:key => "global.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_ios_stat = Stats.new(:key => "global-ios.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_android_stat = Stats.new(:key => "global-android.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)
    global_joint_stat = Stats.new(:key => "global-joint.#{date.strftime('%Y-%m-%d')}", :load_from_memcache => false)

    global_stats = [global_stat, global_ios_stat, global_android_stat, global_joint_stat]

    global_stats.each do |stat|
      stat.parsed_values.clear
      stat.parsed_countries.clear
    end

    Partner.find_each do |partner|
      partner_stat = Stats.new(:key => "partner.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_ios_stat = Stats.new(:key => "partner-ios.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_android_stat = Stats.new(:key => "partner-android.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)
      partner_joint_stat = Stats.new(:key => "partner-joint.#{date.strftime('%Y-%m-%d')}.#{partner.id}", :load_from_memcache => false)

      partner_stats = [partner_stat, partner_ios_stat, partner_android_stat, partner_joint_stat]

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

  def self.aggregate_daily_group_stats(date = nil)
    date ||= Time.zone.now
    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  date.beginning_of_day ])
    daily_stat = Stats.new(:key => "global.#{date.strftime('%Y-%m')}", :load_from_memcache => false, :consistent => true)
    if num_unverified > 0
      Rails.logger.info "there are #{num_unverified} offers with unverified stats, not aggregating global stats yet"
    elsif daily_stat.get_daily_count('logins')[date.day - 1] > 0
      Rails.logger.info "stats have already been aggregated for date: #{date}"
    else
      aggregate_hourly_group_stats(date.yesterday, true)
    end
  end

  def self.sum_arrays(array1, array2)
    array1.zip(array2).map { |pair| pair[0] + pair[1] }
  end
end
