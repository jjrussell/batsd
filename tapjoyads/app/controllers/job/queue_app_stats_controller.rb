class Job::QueueAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS
    @paths_to_aggregate = %w(connect new_user adshown store_click daily_user monthly_user purchased_vg offers)
    @publisher_paths_to_aggregate = %w(store_click offer_click rate_app)
    @displayer_paths_to_aggregate = %w(display_ad_requested display_ad_shown store_click)
  end
  
private
  
  def on_message(message)
    @offer = Offer.find(message.to_s)
    @now = Time.zone.now
    @stat_rows = {}
    
    last_run_time = @offer.last_stats_aggregation_time || Time.zone.now.beginning_of_day
    
    start_time = last_run_time.beginning_of_hour
    end_time = (@now - 30.minutes).beginning_of_hour
    
    Rails.logger.info "Aggregating stats for #{@offer.name} (#{@offer.id}) from #{start_time} to #{end_time}"
    
    while start_time < end_time do
      count_stats_for_hour(start_time)
      start_time += 1.hour
    end
    
    @stat_rows.each_value do |row|
      row.save
    end
    
    @offer.stats_aggregation_interval = get_interval
    @offer.next_stats_aggregation_time = @now + @offer.stats_aggregation_interval
    @offer.last_stats_aggregation_time = end_time
    verify_yesterday
    @offer.save!
  end
  
  def count_stats_for_hour(start_time)
    end_time = start_time + 1.hour
    date_string = start_time.to_date.to_s(:db)
    stat_row = @stat_rows[date_string] || Stats.new(:key => "app.#{date_string}.#{@offer.id}")
    @stat_rows[date_string] = stat_row
    
    Rails.logger.info "Counting hour from #{start_time} to #{end_time}"
    
    time_condition = "time >= '#{start_time.to_f.to_s}' and time < '#{end_time.to_f.to_s}'"
    
    @paths_to_aggregate.each do |path|
      stat_name = WebRequest::PATH_TO_STAT_MAP[path]
      app_condition = WebRequest::USE_OFFER_ID.include?(path) ? "offer_id = '#{@offer.id}'" : "app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      if path == 'store_click'
        count += WebRequest.count(:date => date_string, :where => "#{time_condition} and path = 'offer_click' and #{app_condition}")
      end
      
      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    paid_installs = Conversion.count(:conditions => ["advertiser_offer_id = ? and created_at >= ? and created_at < ? and reward_type in (0, 1, 3)", @offer.id, start_time, end_time])
    installs_spend = Conversion.sum(:advertiser_amount, :conditions => ["advertiser_offer_id = ? and created_at >= ? and created_at < ? and reward_type in (0, 1, 3)", @offer.id, start_time, end_time])
    stat_row.update_stat_for_hour('paid_installs', start_time.hour, paid_installs)
    stat_row.update_stat_for_hour('installs_spend', start_time.hour, installs_spend)
    
    installs_opened, offers_opened = 0
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      installs_opened = count if path == 'store_click'
      offers_opened = count if path == 'offer_click'

      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    published_installs = Conversion.count(:conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    installs_revenue = Conversion.sum(:publisher_amount, :conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    offers_completed = Conversion.count(:conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type in (0, 3)", @offer.id, start_time, end_time])
    offers_revenue = Conversion.sum(:publisher_amount, :conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type in (0, 3)", @offer.id, start_time, end_time])
    
    stat_row.update_stat_for_hour('published_installs', start_time.hour, published_installs)
    stat_row.update_stat_for_hour('installs_revenue', start_time.hour, installs_revenue)
    stat_row.update_stat_for_hour('offers', start_time.hour, offers_completed)
    stat_row.update_stat_for_hour('offers_revenue', start_time.hour, offers_revenue)
    
    @displayer_paths_to_aggregate.each do |path|
      stat_name = WebRequest::DISPLAYER_PATH_TO_STAT_MAP[path]
      app_condition = "displayer_app_id = '#{@offer.id}'"
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    display_conversions = Conversion.count(:conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type in (1000, 1001, 1003)", @offer.id, start_time, end_time])
    display_revenue = Conversion.sum(:publisher_amount, :conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type in (1000, 1001, 1003)", @offer.id, start_time, end_time])
    
    stat_row.update_stat_for_hour('display_conversions', start_time.hour, display_conversions)
    stat_row.update_stat_for_hour('display_revenue', start_time.hour, display_revenue)
    
    if @offer.item_type == 'App' && @offer.get_platform == 'iOS'
      if stat_row.get_hourly_count('overall_store_rank', 0)[start_time.hour].to_i == 0
        stat_row.update_stat_for_hour('overall_store_rank', start_time.hour, get_store_rank(@offer.third_party_data))
      end
    end
  end
  
  ##
  #
  def verify_yesterday
    return unless @offer.last_daily_stats_aggregation_time.nil? || @offer.last_daily_stats_aggregation_time.day != @now.day
    return if @now.hour == 0
    
    start_time = (@now - 1.day).beginning_of_day
    end_time = start_time + 1.day
    date_string = start_time.to_date.to_s(:db)
    stat_row = @stat_rows[date_string] || Stats.new(:key => "app.#{date_string}.#{@offer.id}")
    @stat_rows[date_string] = stat_row
    
    Rails.logger.info "Verifying stats for offer #{@offer.name} (#{@offer.id}) for #{date_string}"
    
    time_condition = "time >= '#{start_time.to_f.to_s}' and time < '#{end_time.to_f.to_s}'"
    
    @paths_to_aggregate.each do |path|
      stat_name = WebRequest::PATH_TO_STAT_MAP[path]
      app_condition = WebRequest::USE_OFFER_ID.include?(path) ? "offer_id = '#{@offer.id}'" : "app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      if path == 'store_click'
        count += WebRequest.count(:date => date_string, :where => "#{time_condition} and path = 'offer_click' and #{app_condition}")
      end
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    @displayer_paths_to_aggregate.each do |path|
      stat_name = WebRequest::DISPLAYER_PATH_TO_STAT_MAP[path]
      app_condition = "displayer_app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    daily_date_string = start_time.strftime('%Y-%m')
    daily_stat_row = Stats.new(:key => "app.#{daily_date_string}.#{@offer.id}")
    daily_stat_row.populate_daily_from_hourly(stat_row, start_time.day - 1)
    daily_stat_row.save
    
    @offer.last_daily_stats_aggregation_time = @now
  rescue AppStatsVerifyError => e
    @offer.last_stats_aggregation_time = start_time
    @offer.next_stats_aggregation_time = @now
    
    msg = "Verification of stats failed for offer: #{@offer.name} (#{@offer.id}), for date: #{start_time.to_date}. #{e.message}"
    Rails.logger.info msg
    Notifier.alert_new_relic(AppStatsVerifyError, msg, request, params)
  end
  
  ##
  # Gets the updates interval for this app, based on the contents of stat_row. 
  def get_interval
    stat_row = @stat_rows.values[0]
    if @now.hour <= 4 || stat_row.nil?
      # Never calculate the interval during the first 4 hours of a day.
      # This is because it's possible that stats haven't been tallied yet.
      # Just use the previously set interval.
      app_update_time = @offer.stats_aggregation_interval || 1.hour
      return [app_update_time.to_i, 1.hour].max
    end
    
    total_logins = stat_row.get_hourly_count('logins').sum
    offerwall_views = stat_row.get_hourly_count('offerwall_views').sum
    total_paid_clicks = stat_row.get_hourly_count('paid_clicks').sum
    total_ad_impressions = stat_row.get_hourly_count('hourly_impressions').sum
    
    if total_logins + offerwall_views + total_paid_clicks + total_ad_impressions > 0
      return 1.hour
    else
      return 2.hour
    end
  end
  
  def get_store_rank(store_id)
    top_list = Mc.get_and_put('rankings.itunes.top100', false, 1.hour) do 
      response = Downloader.get('http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?id=25204&popId=27&genreId=36', 
          :headers => {'User-Agent' => 'iTunes/9.1.1 (Macintosh; Intel Mac OS X 10.6.3) AppleWebKit/531.22.7'},
          :timeout => 30)
      response.scan(/<GotoURL.*?url=\S*\/app\/\S*\id(\d*)\?/m).uniq.flatten
    end
    top_list.each_with_index do |id, index|
      return index + 1 if id == store_id
    end
    return '-'
  end
end
