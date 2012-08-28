class Utils
  require 'open-uri'

  def self.check_syntax
    # TODO: Find a rails 3 compatible way to do this
    # Or fuck it... maybe it's bad code somewhere
    #Rails::Initializer.run(:load_application_classes)

    # haml
    Dir.glob("app/views/**/*.haml").each do |f|
      Haml::Engine.new(File.read(f))
    end

    true
  end

  def self.update_sqlite_schema
    ActiveRecord::Base.establish_connection('sqlite')
    load('db/schema.rb')
    ActiveRecord::Base.establish_connection(Rails.env)
    true
  end

  def self.import_udids(filename, app_id, udid_regex = //)
    counter = 0
    new_udids = 0
    existing_udids = 0
    app_new_udids = 0
    app_existing_udids = 0
    invalid_udids = 0
    parse_errors = 0
    now = "%.5f" % Time.zone.now.to_f
    puts "opening #{filename}"
    file = nil
    outfile = nil
    time = Benchmark.realtime do
      file = open(filename, 'r')
      outfile = File.open("import_udids_#{Time.now.strftime('%Y%m%dT%H%M%S%z')}.parse_errors", 'w')
    end
    puts "Finished opening file in #{time.ceil} seconds"
    time = Benchmark.realtime do
      file.each_line do |line|
        counter += 1
        udid = line.gsub("\r","").gsub("\n", "").gsub('"', '').downcase
        if counter == 1
          udid.gsub!(/^\xEF\xBB\xBF/, '') # remove UTF-8 Byte Order Mark, if it exists
        end
        if (udid !~ udid_regex) || udid.to_s.strip.blank?
          invalid_udids += 1
          next
        end
        begin
          begin
            device = Device.new(:key => udid)
          rescue JSON::ParserError
            parse_errors += 1
            outfile.puts(udid)
            next
          end
          device.is_new ? new_udids += 1 : existing_udids += 1
          if device.has_app? app_id
            app_existing_udids += 1
          else
            app_new_udids += 1
            apps_hash = device.parsed_apps
            apps_hash[app_id] = now
            device.apps = apps_hash
            begin
              device.save!
            rescue
              puts "device save failed for UDID: #{udid}   retrying..."
              sleep 0.2
              retry
            end
          end
        rescue => e
          puts "Encountered unexpected error while processing udid: #{udid}"
          raise e
        end
        puts "#{Time.zone.now.to_s(:db)} - finished #{counter} UDIDs, #{new_udids} new (global), #{existing_udids} existing (global), #{app_new_udids} new (per app), #{app_existing_udids} existing (per app), #{invalid_udids} invalid, #{parse_errors} parse errors" if counter % 1000 == 0
      end
    end
    puts "finished importing #{counter} UDIDs in #{time.ceil} seconds"
    puts "new UDIDs (global): #{new_udids}"
    puts "existing UDIDs (global): #{existing_udids}"
    puts "new UDIDs (per app): #{app_new_udids}"
    puts "existing UDIDs (per app): #{app_existing_udids}"
    puts "invalid UDIDs: #{invalid_udids}"
    puts "parse errors: #{parse_errors}"
  ensure
    file.close
    outfile.close
  end

  def self.rewards_to_csv(where_clause, outfile)
    file = File.open(outfile, 'w')
    file.puts("reward_id,publisher_app_id,udid,publisher_amount,created_at,sent_currency_at")
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:where => where_clause, :domain_name => "rewards_#{i}") do |r|
        file.puts("#{r.key},#{r.publisher_app_id},#{r.udid},#{r.publisher_amount},#{r.created.to_f},#{r.sent_currency.to_f}")
      end
    end
    file.close
  end

  def self.get_publisher_breakdown_for_campaign(advertiser_app_id, start_time, end_time)
    counts = {}
    NUM_REWARD_DOMAINS.times do |i|
      domain_name = "rewards_#{i}"
      puts "#{Time.zone.now.to_s(:db)} - selecting over #{domain_name}..."
      Reward.select(:domain_name => domain_name, :where => "advertiser_app_id = '#{advertiser_app_id}' AND created >= '#{start_time.to_i}' AND created < '#{end_time.to_i}'") do |r|
        counts[r.publisher_app_id] ||= 0
        counts[r.publisher_app_id] += 1
      end
    end
    counts
  end

  def self.fix_stuck_send_currency(reward_id, status)
    reward = Reward.find(reward_id, :consistent => true)
    if reward.sent_currency.present? && reward.send_currency_status.present?
      puts "already awarded"
    elsif reward.sent_currency.present?
      puts "sent_currency present"
    else
      reward.sent_currency = Time.zone.now
      reward.send_currency_status = status
      reward.save!
      puts "fixed"
    end
    reward
  end

  def self.cleanup_orphaned_failed_sdb_saves
    time = Time.zone.now - 24.hours
    count = 0
    bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
    bucket.objects.with_prefix('incomplete/').each do |obj|
      if obj.last_modified < time
        count += 1
        puts "moving: #{obj.key} - last modified: #{obj.last_modified}"
        obj.copy_to(obj.key.gsub('incomplete', 'orphaned'))
        obj.delete
      end
    end
    puts "moved #{count} orphaned items from #{BucketNames::FAILED_SDB_SAVES}"
  end

  def self.resend_failed_callbacks(currency_id, status)
    count = 0
    Reward.select_all(:conditions => "currency_id = '#{currency_id}' and send_currency_status = '#{status}'") do |reward|
      reward.delete('sent_currency')
      reward.delete('send_currency_status')
      begin
        reward.save!
      rescue
        puts "save failed... retrying"
        sleep 0.1
        retry
      end
      Sqs.send_message(QueueNames::SEND_CURRENCY, reward.key)
      count += 1
    end
    count
  end

  class Memcache
    # Use these functions to facilitate switching memcache servers.
    #
    # 'XX' is the current UTC hour
    #
    # shortly after XX:05
    # -stop master hourly app stats job
    # -run Utils::Memcache.aggregate_all_stats
    # -wait until Utils::Memcache.all_stats_aggregated? returns true
    # -run Utils::Memcache.advance_last_stats_aggregation_times
    #
    # shortly after XX:30 (all steps must be completed by XX:59)
    # This should only be run on hashed keys, distributed keys will
    # filter back in once a new cluster/server is online and ready for
    # keys.  If you *absolutely must*, don't.
    #
    # -run Utils::Memcache.save_hashed_state
    # -deploy new config to util server
    # -verify new memcache servers are functioning (Mc.cache.stats)
    # -if you're reusing a memcache server, run Mc.cache.flush
    # -run Utils::Memcache.restore_hashed_state
    # -deploy new config to production servers
    #
    # shortly after XX+1:05
    # -run Utils::Memcache.queue_recount_stats_jobs
    #
    # after recount jobs have completed
    # -enable master hourly app stats job

    HASHED_KEYS = %w(
      statz.last_updated_start.24_hours
      statz.last_updated_start.7_days
      statz.last_updated_start.1_month
      statz.last_updated_end.24_hours
      statz.last_updated_end.7_days
      statz.last_updated_end.1_month
      statz.partner.last_updated_start.24_hours
      statz.partner.last_updated_start.7_days
      statz.partner.last_updated_start.1_month
      statz.partner.last_updated_end.24_hours
      statz.partner.last_updated_end.7_days
      statz.partner.last_updated_end.1_month
      statz.partner-ios.last_updated_start.24_hours
      statz.partner-ios.last_updated_start.7_days
      statz.partner-ios.last_updated_start.1_month
      statz.partner-ios.last_updated_end.24_hours
      statz.partner-ios.last_updated_end.7_days
      statz.partner-ios.last_updated_end.1_month
      statz.partner-windows.last_updated_start.24_hours
      statz.partner-windows.last_updated_start.7_days
      statz.partner-windows.last_updated_start.1_month
      statz.partner-windows.last_updated_end.24_hours
      statz.partner-windows.last_updated_end.7_days
      statz.partner-windows.last_updated_end.1_month
      statz.partner-android.last_updated_start.24_hours
      statz.partner-android.last_updated_start.7_days
      statz.partner-android.last_updated_start.1_month
      statz.partner-android.last_updated_end.24_hours
      statz.partner-android.last_updated_end.7_days
      statz.partner-android.last_updated_end.1_month
      store_ranks.android.overall.free.english
      store_ranks.android.overall.paid.english
      store_ranks.ios.overall.free.united_states
      store_ranks.ios.overall.paid.united_states
      money.cached_stats
      money.total_balance
      money.total_pending_earnings
      money.last_updated
    )
    DISTRIBUTED_KEYS = %w(
      statz.metadata.24_hours
      statz.metadata.7_days
      statz.metadata.1_month
      statz.stats.24_hours
      statz.stats.7_days
      statz.stats.1_month
      statz.top_metadata.24_hours
      statz.top_metadata.7_days
      statz.top_metadata.1_month
      statz.top_stats.24_hours
      statz.top_stats.7_days
      statz.top_stats.1_month
      statz.money.24_hours
      statz.money.7_days
      statz.money.1_month
      statz.partner.cached_stats.24_hours
      statz.partner.cached_stats.7_days
      statz.partner.cached_stats.1_month
      statz.partner-ios.cached_stats.24_hours
      statz.partner-ios.cached_stats.7_days
      statz.partner-ios.cached_stats.1_month
      statz.partner-windows.cached_stats.24_hours
      statz.partner-windows.cached_stats.7_days
      statz.partner-windows.cached_stats.1_month
      statz.partner-android.cached_stats.24_hours
      statz.partner-android.cached_stats.7_days
      statz.partner-android.cached_stats.1_month
      tools.disabled_popular_offers
      cached_apps.popular_ios
      cached_apps.popular_android
    )

    def self.save_state
      save_hashed_state
      save_distributed_state
    end

    def self.save_hashed_state
      HASHED_KEYS.each do |key|
        data = Mc.get(key)

        File.open("tmp/mc_#{key}", 'w') do |f|
          f.write(Marshal.dump(data))
        end
      end
      true
    end

    def self.save_distributed_state
      DISTRIBUTED_KEYS.each do |key|
        data = Mc.distributed_get(key)

        File.open("tmp/mc_#{key}", 'w') do |f|
          f.write(Marshal.dump(data))
        end
      end
      true
    end

    def self.restore_state
      restore_hashed_state
      restore_distributed_state
    end

    def self.restore_hashed_state
      HASHED_KEYS.each do |key|
        f = File.open("tmp/mc_#{key}", 'r')
        data = Marshal.restore(f.read)
        f.close

        Mc.put(key, data)
      end
      OfferCacher.cache_offer_stats
      OfferCacher.cache_papaya_offers
      true
    end

    def self.restore_distributed_state
      DISTRIBUTED_KEYS.each do |key|
        f = File.open("tmp/mc_#{key}", 'r')
        data = Marshal.restore(f.read)
        f.close

        Mc.distributed_put(key, data)
      end
      OfferCacher.cache_offers
      SpendShare.current_ratio
      Mc.cache_all
      true
    end

    def self.aggregate_all_stats
      cutoff = Time.now.utc.beginning_of_hour
      Offer.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE, :conditions => ["last_stats_aggregation_time < ?", cutoff]) do |offers|
        message = offers.map(&:id).to_json
        Sqs.send_message(QueueNames::APP_STATS_HOURLY, message)
      end
    end

    def self.all_stats_aggregated?
      cutoff = Time.now.utc.beginning_of_hour
      Offer.count(:conditions => ["last_stats_aggregation_time < ?", cutoff]) == 0
    end

    def self.advance_last_stats_aggregation_times
      last_aggregation_time = Time.now.utc.beginning_of_hour + 1.hour
      Offer.find_in_batches(:batch_size => 1000, :conditions => ["last_stats_aggregation_time < ?", last_aggregation_time]) do |offers|
        offer_ids = offers.map(&:id)
        Offer.connection.execute("UPDATE offers SET last_stats_aggregation_time = '#{last_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
      end
    end

    def self.queue_recount_stats_jobs
      end_time   = Time.now.utc.beginning_of_hour
      start_time = end_time - 1.hour

      StatsAggregation.cache_vertica_stats(start_time, end_time)

      Offer.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE) do |offers|
        message = { :offer_ids => offers.map(&:id), :start_time => start_time.to_i, :end_time => end_time.to_i }.to_json
        Sqs.send_message(QueueNames::RECOUNT_STATS, message)
      end
    end
  end

end
