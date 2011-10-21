Dir[File.dirname(__FILE__) + '/one_offs/*.rb'].each { |file| require(file) }

class OneOffs

  def self.copy_ranks_to_s3(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity_string == 'daily'
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time < end_time
      copy_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.copy_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      puts stats.key
      ranks_key = stats.key.gsub('app', 'ranks').gsub('.', '/')
      ranks = {}
      stats.parsed_ranks.each do |key, value|
        ranks[key] = value
      end
      unless ranks.empty?
        s3_ranks = S3Stats::Ranks.find_or_initialize_by_id(ranks_key)
        s3_ranks.all_ranks = ranks
        s3_ranks.save!
      end
    end
  end

  def self.delete_ranks_from_sdb(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity == :daily
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time < end_time
      delete_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.delete_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      stats.delete('ranks')
      stats.serial_save
    end
  end

  def self.aggregate_global_platform_stats(date = nil)
    date ||= Time.zone.now.beginning_of_day
    puts "starting aggregation for #{date}"
    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  date.beginning_of_day ])
    if num_unverified > 0
      puts "there are #{num_unverified} offers with unverified stats, not aggregating global stats yet for #{date}"
    else
      StatsAggregation.aggregate_hourly_group_stats(date, true)
    end
    puts "done aggregating for #{date}"
  end

  def self.aggregate_all_global_platform_stats(date = nil)
    date ||= Time.zone.parse('2009-09-01')
    while date < Time.zone.now
      aggregate_global_platform_stats(date)
      date += 1.day
    end
  end

  def self.add_jobs
    jobs = [
      { :job_type => 'queue',  :controller => 'queue_conversion_tracking',                    :action => 'index',              :frequency => 'interval', :seconds => 1.second },
      { :job_type => 'queue',  :controller => 'queue_create_conversions',                     :action => 'index',              :frequency => 'interval', :seconds => 1.second },
      { :job_type => 'queue',  :controller => 'queue_failed_sdb_saves',                       :action => 'index',              :frequency => 'interval', :seconds => 2.seconds },
      { :job_type => 'queue',  :controller => 'queue_failed_web_request_saves',               :action => 'index',              :frequency => 'interval', :seconds => 2.seconds },
      { :job_type => 'queue',  :controller => 'queue_send_currency',                          :action => 'index',              :frequency => 'interval', :seconds => 1.second },
      { :job_type => 'queue',  :controller => 'queue_failed_downloads',                       :action => 'index',              :frequency => 'interval', :seconds => 2.seconds },
      { :job_type => 'queue',  :controller => 'queue_hourly_app_stats',                       :action => 'index',              :frequency => 'interval', :seconds => 10.seconds },
      { :job_type => 'queue',  :controller => 'queue_daily_app_stats',                        :action => 'index',              :frequency => 'interval', :seconds => 15.seconds },
      { :job_type => 'queue',  :controller => 'queue_pre_create_domains',                     :action => 'index',              :frequency => 'interval', :seconds => 2.minutes },
      { :job_type => 'queue',  :controller => 'queue_calculate_show_rate',                    :action => 'index',              :frequency => 'interval', :seconds => 10.seconds },
      { :job_type => 'queue',  :controller => 'queue_select_vg_items',                        :action => 'index',              :frequency => 'interval', :seconds => 30.seconds },
      { :job_type => 'queue',  :controller => 'queue_get_store_info',                         :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_update_monthly_account',                 :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_sdb_backups',                            :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_mail_chimp_updates',                     :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_partner_notifications',                  :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_recount_stats',                          :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'queue',  :controller => 'queue_udid_reports',                           :action => 'index',              :frequency => 'interval', :seconds => 15.seconds },
      { :job_type => 'queue',  :controller => 'queue_cache_offers',                           :action => 'index',              :frequency => 'interval', :seconds => 2.seconds },
      { :job_type => 'master', :controller => 'master_calculate_next_payout',                 :action => 'index',              :frequency => 'daily',    :seconds => 4.hours },
      { :job_type => 'master', :controller => 'master_udid_reports',                          :action => 'index',              :frequency => 'daily',    :seconds => 2.hours },
      { :job_type => 'master', :controller => 'master_update_monthly_account',                :action => 'index',              :frequency => 'daily',    :seconds => 8.hours },
      { :job_type => 'master', :controller => 'master_verifications',                         :action => 'index',              :frequency => 'daily',    :seconds => 5.hours },
      { :job_type => 'master', :controller => 'master_hourly_app_stats',                      :action => 'index',              :frequency => 'interval', :seconds => 2.minutes },
      { :job_type => 'master', :controller => 'master_daily_app_stats',                       :action => 'index',              :frequency => 'interval', :seconds => 2.minutes },
      { :job_type => 'master', :controller => 'master_calculate_show_rate',                   :action => 'index',              :frequency => 'interval', :seconds => 20.minutes },
      { :job_type => 'master', :controller => 'master_reload_money',                          :action => 'index',              :frequency => 'interval', :seconds => 20.minutes },
      { :job_type => 'master', :controller => 'master_reload_statz',                          :action => 'index',              :frequency => 'interval', :seconds => 20.minutes },
      { :job_type => 'master', :controller => 'master_reload_statz',                          :action => 'daily',              :frequency => 'daily',    :seconds => 10.minutes },
      { :job_type => 'master', :controller => 'master_reload_statz',                          :action => 'partner_index',      :frequency => 'hourly',   :seconds => 7.minutes },
      { :job_type => 'master', :controller => 'master_reload_statz',                          :action => 'partner_daily',      :frequency => 'daily',    :seconds => 10.minutes },
      { :job_type => 'master', :controller => 'master_ios_app_ranks',                         :action => 'index',              :frequency => 'hourly',   :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_android_app_ranks',                     :action => 'index',              :frequency => 'hourly',   :seconds => 30.minutes },
      { :job_type => 'master', :controller => 'master_group_daily_stats',                     :action => 'index',              :frequency => 'hourly',   :seconds => 5.minutes },
      { :job_type => 'master', :controller => 'master_group_hourly_stats',                    :action => 'index',              :frequency => 'hourly',   :seconds => 6.minutes },
      { :job_type => 'master', :controller => 'master_external_publishers',                   :action => 'populate_potential', :frequency => 'daily',    :seconds => 1.hour },
      { :job_type => 'master', :controller => 'master_refresh_memcached',                     :action => 'index',              :frequency => 'interval', :seconds => 10.minutes },
      { :job_type => 'master', :controller => 'master_cleanup_web_requests',                  :action => 'index',              :frequency => 'daily',    :seconds => 5.hours },
      { :job_type => 'master', :controller => 'master_failed_sqs_writes',                     :action => 'index',              :frequency => 'interval', :seconds => 3.minutes },
      { :job_type => 'master', :controller => 'master_get_store_info',                        :action => 'index',              :frequency => 'daily',    :seconds => 7.hours },
      { :job_type => 'master', :controller => 'master_grab_disabled_popular_offers',          :action => 'index',              :frequency => 'daily',    :seconds => 8.hours },
      { :job_type => 'master', :controller => 'master_pre_create_domains',                    :action => 'index',              :frequency => 'daily',    :seconds => 6.hours },
      { :job_type => 'master', :controller => 'master_select_vg_items',                       :action => 'index',              :frequency => 'interval', :seconds => 5.minutes },
      { :job_type => 'master', :controller => 'master_set_bad_domains',                       :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_update_rev_share',                      :action => 'index',              :frequency => 'daily',    :seconds => 1.hour },
      { :job_type => 'master', :controller => 'master_set_exclusivity_and_premier_discounts', :action => 'index',              :frequency => 'daily',    :seconds => 2.hours },
      { :job_type => 'master', :controller => 'master_partner_notifications',                 :action => 'index',              :frequency => 'daily',    :seconds => 17.hours },
      { :job_type => 'master', :controller => 'master_archive_conversions',                   :action => 'index',              :frequency => 'daily',    :seconds => 6.hours },
      { :job_type => 'master', :controller => 'master_healthz',                               :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_run_offer_events',                      :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_fetch_top_freemium_android_apps',       :action => 'index',              :frequency => 'daily',    :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_calculate_ranking_fields',              :action => 'index',              :frequency => 'interval', :seconds => 30.minutes },
      { :job_type => 'master', :controller => 'master_cache_offers',                          :action => 'index',              :frequency => 'interval', :seconds => 1.minute },
      { :job_type => 'master', :controller => 'master_external_publishers',                   :action => 'cache',              :frequency => 'hourly',   :seconds => 6.minutes },
    ]

    jobs.each do |job|
      j = Job.new(job)
      j.active = true
      j.save!
    end
  end

  def self.migrate_payout_info_countries
    PayoutInfo.find_each do |info|
      info.update_attribute(:payment_country => info.address_country)
    end
  end

  def self.migrate_app_metadata
    App.find_each(:conditions => "store_id != ''") do |app|
      app_metadata = AppMetadata.find(:first, :conditions => ["store_name = ? and store_id = ?", app.store_name, app.store_id])
      if app_metadata == nil
        # only create this record if one doesn't already exist for this store and store_id
        app_metadata = AppMetadata.create!(
          :name              => app.name,
          :description       => app.description,
          :price             => app.price,
          :store_name        => app.store_name,
          :store_id          => app.store_id,
          :age_rating        => app.age_rating,
          :file_size_bytes   => app.file_size_bytes,
          :supported_devices => app.supported_devices,
          :released_at       => app.released_at,
          :user_rating       => app.user_rating,
          :categories        => app.categories
        )
      end

      app_metadata.apps << app
    end
  end

  def self.populate_instructions
    ActionOffer.connection.execute("update action_offers set instructions = 'Enter your instructions here.' where instructions is null")
  end
end

