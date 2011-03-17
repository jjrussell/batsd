class StatsAggregation
  
  def self.recount_stats_over_range(start_time, end_time)
    Offer.find_each do |offer|
      puts "#{Time.zone.now.to_s(:db)} - #{offer.id}"
      hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)
      
      verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
      verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)
      
      hourly_stat_row.serial_save
    end
  end
  
  def self.verify_and_populate_daily_stats(offer_id)
    offer      = Offer.find(offer_id)
    now        = Time.zone.now
    start_time = offer.last_daily_stats_aggregation_time || (now - 1.day).beginning_of_day
    end_time   = start_time + 1.day
    
    return if end_time > now
    
    hourly_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m-%d')}.#{offer.id}", :load_from_memcache => false)
    
    verify_web_request_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    verify_conversion_stats_over_range(hourly_stat_row, offer, start_time, end_time)
    
    daily_stat_row = Stats.new(:key => "app.#{start_time.strftime('%Y-%m')}.#{offer.id}", :load_from_memcache => false)
    daily_stat_row.populate_daily_from_hourly(hourly_stat_row, start_time.day - 1)
    daily_stat_row.serial_save
    hourly_stat_row.serial_save
    
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
          if country == 'other'
            values_by_country[key].reject { |c, value| Stats::COUNTRY_CODES[c].present? }.values.sum
          else
            values_by_country[key][country] || 0
          end
        end
      end
    end
  end
  
  def self.verify_stat_over_range(stat_row, stat_name_or_path, offer, start_time, end_time)
    value_over_range = yield(start_time, end_time)
    hourly_values = stat_row.get_hourly_count(stat_name_or_path)
    
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
  
end
