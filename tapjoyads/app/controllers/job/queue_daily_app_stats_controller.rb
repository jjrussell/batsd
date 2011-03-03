class Job::QueueDailyAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS_DAILY
    @num_reads = 10
  end
  
private
  
  def on_message(message)
    @offer       = Offer.find(message.to_s)
    now          = Time.zone.now
    @start_time  = @offer.last_daily_stats_aggregation_time || (now - 1.day).beginning_of_day
    @end_time    = @start_time + 1.day
    @date_string = @start_time.strftime('%Y-%m-%d')
    
    return if @end_time > now
    
    @hourly_stat_row = Stats.new(:key => "app.#{@date_string}.#{@offer.id}", :load_from_memcache => false)
    
    verify_web_request_stats
    verify_conversion_stats
    
    daily_stat_row = Stats.new(:key => "app.#{@start_time.strftime('%Y-%m')}.#{@offer.id}", :load_from_memcache => false)
    daily_stat_row.populate_daily_from_hourly(@hourly_stat_row, @start_time.day - 1)
    daily_stat_row.serial_save
    @hourly_stat_row.serial_save
    
    @offer.last_daily_stats_aggregation_time = @end_time
    @offer.next_daily_stats_aggregation_time = @end_time + 1.day + Offer::DAILY_STATS_START_HOUR.hours + rand(Offer::DAILY_STATS_RANGE.hours)
    @offer.save!
  end
  
  def verify_web_request_stats
    WebRequest::STAT_TO_PATH_MAP.each do |stat, path_definition|
      conditions = "#{get_path_condition(path_definition[:paths])} AND #{path_definition[:attr_name]} = '#{@offer.id}'"
      verify_stat(stat) do |start_time, end_time|
        WebRequest.count(:date => @date_string, :where => "#{conditions} AND #{get_time_condition(start_time, end_time)}")
      end
    end
    
    if @hourly_stat_row.get_hourly_count('vg_purchases').sum > 0
      @offer.virtual_goods.each do |virtual_good|
        stat_path = [ 'virtual_goods', virtual_good.key ]
        conditions = "path = 'purchased_vg' AND app_id = '#{@offer.id}' AND virtual_good_id = '#{virtual_good.key}'"
        verify_stat(stat_path) do |start_time, end_time|
          WebRequest.count(:date => @date_string, :where => "#{conditions} AND #{get_time_condition(start_time, end_time)}")
        end
      end
    end
  end
  
  def verify_conversion_stats
    Conversion::STAT_TO_REWARD_TYPE_MAP.each do |stat, rtd|
      conditions = [ "#{rtd[:attr_name]} = ? AND reward_id IN (?)", @offer.id, rtd[:reward_ids] ]
      verify_stat(stat) do |start_time, end_time|
        Conversion.using_slave_db do
          if rtd[:sum_attr].present?
            Conversion.created_between(start_time, end_time).sum(rtd[:sum_attr], :conditions => conditions)
          else
            Conversion.created_between(start_time, end_time).count(:conditions => conditions)
          end
        end
      end
      
      next unless stat == 'paid_installs' || stat == 'installs_spend'
      
      values_by_country = {}
      (Stats::TOP_COUNTRIES + 'other').each do |country|
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
            values_by_country[key].reject { |country, value| Stats::TOP_COUNTRIES.include?(country) }.values.sum
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
      Notifier.alert_new_relic(AppStatsVerifyError, message, request, params)
      
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
  
  def get_time_condition(start_time, end_time)
    "time >= '#{start_time.to_f}' AND time < '#{end_time.to_f}'"
  end
  
  def get_path_condition(paths)
    path_condition = paths.map { |p| "path = '#{p}'" }.join(' OR ')
    "(#{path_condition})"
  end
  
end
