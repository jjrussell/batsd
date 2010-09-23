class Job::QueueAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS
    @paths_to_aggregate = %w(connect new_user adshown store_click daily_user monthly_user purchased_vg offers)
    @publisher_paths_to_aggregate = %w(store_click offer_click rate_app)
  end
  
private
  
  def on_message(message)
    @offer = Offer.find(message.to_s)
    @now = Time.zone.now
    @stat_rows = {}
    
    last_run_time = @offer.last_stats_aggregation_time || Time.zone.now.beginning_of_day
    
    start_time = last_run_time.beginning_of_hour
    end_time = (@now - 5.minutes).beginning_of_hour
    
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
    
    (last_run_time - 1.day).to_date.upto(@now.to_date) do |date|
      send_stats_to_mssql(date)
    end
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
      
      count = WebRequest.count(:date => date_string,
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      
      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    paid_installs = Conversion.count(:conditions => ["advertiser_offer_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    installs_spend = Conversion.sum(:advertiser_amount, :conditions => ["advertiser_offer_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    stat_row.update_stat_for_hour('paid_installs', start_time.hour, paid_installs)
    stat_row.update_stat_for_hour('installs_spend', start_time.hour, installs_spend)
    
    installs_opened, offers_opened, ratings_opened = 0
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string,
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      installs_opened = count if path == 'store_click'
      offers_opened = count if path == 'offer_click'
      ratings_opened = count if path == 'rate_app'

      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    published_installs = Conversion.count(:conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    installs_revenue = Conversion.sum(:publisher_amount, :conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 1", @offer.id, start_time, end_time])
    offers_completed = Conversion.count(:conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 0", @offer.id, start_time, end_time])
    offers_revenue = Conversion.sum(:publisher_amount, :conditions => ["publisher_app_id = ? and created_at >= ? and created_at < ? and reward_type = 0", @offer.id, start_time, end_time])
    
    stat_row.update_stat_for_hour('published_installs', start_time.hour, published_installs)
    stat_row.update_stat_for_hour('installs_revenue', start_time.hour, installs_revenue)
    stat_row.update_stat_for_hour('offers', start_time.hour, offers_completed)
    stat_row.update_stat_for_hour('offers_revenue', start_time.hour, offers_revenue)
    # TO REMOVE - when mssql is no more
    stat_row.update_stat_for_hour('rewards', start_time.hour, published_installs + offers_completed)
    stat_row.update_stat_for_hour('rewards_revenue', start_time.hour, installs_revenue + offers_revenue)
    stat_row.update_stat_for_hour('rewards_opened', start_time.hour, installs_opened + offers_opened)
    # END TO REMOVE
    
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
      
      count = WebRequest.count(:date => date_string, 
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@offer.id}'"
      
      count = WebRequest.count(:date => date_string, 
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
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
  
  def send_stats_to_mssql(utc_date)
    unless @offer.is_primary? && (@offer.item_type == 'App' || @offer.item_type == 'EmailOffer')
      return
    end
    
    offset = -6 # CST timezone. Must be negative the way this is currently implemented.
    
    today = utc_date.to_s(:db)
    tomorrow = (utc_date + 1.days).to_s(:db)
    
    stat_today = Stats.new(:key => "app.#{today}.#{@offer.id}")
    stat_tomorrow = Stats.new(:key => "app.#{tomorrow}.#{@offer.id}")
    
    stats = {}
    
    stats_map = {
      'new_users' => 'NewUsers',
      'logins' => 'GameSessions',
      'daily_active_users' => 'UniqueUsers',
      'paid_installs' => 'RewardedInstalls',
      'paid_clicks' => 'RewardedInstallClicks',
      'rewards' => 'CompletedOffers',
      'installs_spend' => 'MoneySpentOnInstalls',
      'rewards_revenue' => 'OfferRevenue',
      'rewards_opened' => 'OffersOpened',
      'hourly_impressions' => 'AdImpressions'
    }
    
    stats_map.each do |sdb_type, sql_type|
      # Last 18 hours of utc-today, first 6 hours of utc-tomorrow.
      today_sum = stat_today.get_hourly_count(sdb_type)[-offset, 24].sum
      tomorrow_sum = stat_tomorrow.get_hourly_count(sdb_type)[0, -offset].sum
      stats[sql_type] = today_sum + tomorrow_sum
    end
    
    stats['RewardedInstallConversionRate'] = (stats['RewardedInstalls'] * 10000 / stats['RewardedInstallClicks']).to_i if stats['RewardedInstallClicks'].to_i > 0
    stats['OfferCompletionRate'] = (stats['CompletedOffers'] * 10000 / stats['OffersOpened']).to_i if stats['OffersOpened'].to_i > 0
    stats['FillRate'] = 10000
    stats['AdRequests'] = stats['AdImpressions']
    stat_types = ''
    datas = ''
    
    should_send = false
    stats.each do |s, d|
      stat_types += ',' unless stat_types == ''
      stat_types += s
      datas += ',' unless datas == ''
      datas += d.to_s
      
      if d != 0 && d != 10000
        should_send = true
      end
    end
    
    if should_send
      send_stats_to_windows(today, stat_types, @offer.id, datas)
    end
  end
  
  def send_stats_to_windows(date, stat_types, item_id, datas)
    url = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/CronService.asmx/SubmitMultipleStats?'

    url += "Date=#{CGI::escape(date)}"
    url += "&StatTypes=#{CGI::escape(stat_types)}"
    url += "&item=#{item_id}"
    url += "&Datas=#{CGI::escape(datas)}"

    Downloader.get_with_retry(url, {:timeout => 30}) if Rails.env == 'production'
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
          :headers => {'User-Agent' => 'iTunes/9.1.1 (Macintosh; Intel Mac OS X 10.6.3) AppleWebKit/531.22.7'})
      response.scan(/<GotoURL.*?url=\S*\/app\/\S*\id(\d*)\?/m).uniq.flatten
    end
    top_list.each_with_index do |id, index|
      return index + 1 if id == store_id
    end
    return '-'
  end
end
