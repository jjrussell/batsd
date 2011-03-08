class FixCountryStats
  
  def run
    time = Time.zone.parse('2011-02-17')
    end_time = Time.zone.parse('2011-03-08')
    while time < end_time
      Offer.find_each do |offer|
        fix_offer(offer, time)
      end
      time += 1.day
    end
  end
  
  def fix_offer(offer, date)
    @offer       = offer
    now          = Time.zone.now
    @start_time  = date
    @end_time    = @start_time + 1.day
    @date_string = @start_time.strftime('%Y-%m-%d')
    
    return if @end_time > now
    
    @hourly_stat_row = Stats.new(:key => "app.#{@date_string}.#{@offer.id}", :load_from_memcache => false)
    
    return if @hourly_stat_row.countries.blank?
    
    verify_conversion_stats
    
    24.times do |hour|
      @hourly_stat_row.update_stat_for_hour(['countries', 'paid_installs.UK'], hour, 0)
      @hourly_stat_row.update_stat_for_hour(['countries', 'installs_spend.UK'], hour, 0)
    end
    
    daily_stat_row = Stats.new(:key => "app.#{@start_time.strftime('%Y-%m')}.#{@offer.id}", :load_from_memcache => false)
    daily_stat_row.populate_daily_from_hourly(@hourly_stat_row, @start_time.day - 1)
    daily_stat_row.update_stat_for_day(['countries', 'paid_installs.UK'], @start_time.day - 1, 0)
    daily_stat_row.update_stat_for_day(['countries', 'installs_spend.UK'], @start_time.day - 1, 0)
    daily_stat_row.serial_save
    @hourly_stat_row.serial_save
  end
  
  def verify_conversion_stats
    Conversion::STAT_TO_REWARD_TYPE_MAP.each do |stat, rtd|
      conditions = [ "#{rtd[:attr_name]} = ? AND reward_type IN (?)", @offer.id, rtd[:reward_types] ]
      next unless stat == 'paid_installs' || stat == 'installs_spend'
      
      values_by_country = {}
      (Stats::COUNTRY_CODES.keys + ['other']).each do |country|
        stat_path = [ 'countries', "#{stat}.#{country}" ]
        verify_stat(stat_path) do |start_time, end_time|
          key = "#{start_time.to_i}-#{end_time.to_i}"
          values_by_country[key] ||= Conversion.using_slave_db do
            if rtd[:sum_attr].present?
              Conversion.created_between(start_time, end_time).sum(rtd[:sum_attr], :conditions => conditions, :group => :country)
            else
              Conversion.created_between(start_time, end_time).count(:conditions => conditions, :group => :country)
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
  
  def verify_stat(stat)
    daily_value = yield(@start_time, @end_time)
    hourly_values = @hourly_stat_row.get_hourly_count(stat)
    
    if daily_value != hourly_values.sum
      message = "Verification of #{stat.inspect} failed for offer: #{@offer.name} (#{@offer.id}), for date: #{@date_string}. Daily value is: #{daily_value}, hourly values are: #{hourly_values.inspect}"
      puts message
      
      start_time = @start_time
      while start_time < @end_time
        hour_value = yield(start_time, start_time + 1.hour)
        hourly_values[start_time.hour] = hour_value
        break if daily_value == hourly_values.sum
        start_time += 1.hour
      end
      
      if daily_value != hourly_values.sum
        message = "Re-counted each hour for #{stat.inspect} and counts do not match the 24-hour count for offer: #{@offer.name} (#{@offer.id}), for date: #{@date_string}. Daily value is: #{daily_value}, hourly sum is: #{hourly_values.sum}"
        raise AppStatsVerifyError.new(message)
      end
    end
  end
  
end
