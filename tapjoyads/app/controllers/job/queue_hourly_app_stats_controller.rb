class Job::QueueHourlyAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS_HOURLY
  end
  
private
  
  def on_message(message)
    offer      = Offer.find(message.to_s)
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
        
        (Stats::COUNTRY_CODES.keys + ['other']).each do |country|
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
      if stat_row.get_hourly_count('offerwall_views').sum > 0 || stat_row.get_hourly_count('paid_clicks').sum > 0
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
