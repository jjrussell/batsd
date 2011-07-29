class Utils
  
  def self.check_syntax
    Rails::Initializer.run(:load_application_classes)

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
    now = Time.zone.now.to_f.to_s
    file = File.open(filename, 'r')
    outfile = File.open("#{filename}.parse_errors", 'w')
    time = Benchmark.realtime do
      file.each_line do |line|
        counter += 1
        udid = line.gsub("\n", "").gsub('"', '').downcase
        if udid !~ udid_regex
          invalid_udids += 1
          next
        end
        begin
          device = Device.new :key => udid
        rescue JSON::ParserError
          parse_errors += 1
          outfile.puts(udid)
          next
        end
        device.is_new ? new_udids += 1 : existing_udids += 1
        if device.has_app app_id
          app_existing_udids += 1
        else
          app_new_udids += 1
          apps_hash = device.apps
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
  
  def self.copy_web_requests_to_tmp(date)
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)

    MAX_WEB_REQUEST_DOMAINS.times do |num|
      s3_name = "#{date}/web-request-#{date}-#{num}.sdb"
      next unless bucket.key(s3_name).exists?
      puts "Found #{s3_name}"

      gzip_file = open("tmp/web-request-#{date}-#{num}.sdb", 'w')
      S3.s3.interface.get(bucket.full_name, s3_name) do |chunk|
        gzip_file.write(chunk)
      end

      gzip_file.close
    end
  end
  
  def self.write_web_requests_from_tmp(date)
    raise "Cannot write to web-requests bucket from a production env" if Rails.env == 'production'
    
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      s3_name = "#{date}/web-request-#{date}-#{num}.sdb"
      puts "Writing #{s3_name}"
      bucket.put(s3_name, open("tmp/web-request-#{date}-#{num}.sdb"))
    end
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
    # -run Utils::Memcache.save_state
    # -deploy new config to test server
    # -verify new memcache servers are functioning (Mc.cache.stats)
    # -run Utils::Memcache.restore_state
    # -deploy new config to production servers
    # 
    # shortly after XX+1:05
    # -run Utils::Memcache.queue_recount_stats_jobs
    # 
    # after recount jobs have completed
    # -enable master hourly app stats job

    def self.save_state
      keys = [ 'statz.last_updated.24_hours',
               'statz.last_updated.7_days',
               'statz.last_updated.1_month',
               'statz.partner.last_updated.24_hours',
               'statz.partner.last_updated.7_days',
               'statz.partner.last_updated.1_month',
               'statz.partner-ios.last_updated.24_hours',
               'statz.partner-ios.last_updated.7_days',
               'statz.partner-ios.last_updated.1_month',
               'statz.partner-android.last_updated.24_hours',
               'statz.partner-android.last_updated.7_days',
               'statz.partner-android.last_updated.1_month',
               'money.cached_stats',
               'money.total_balance',
               'money.total_pending_earnings',
               'money.last_updated' ]
      distributed_keys = [ 'statz.cached_stats.24_hours',
                           'statz.cached_stats.7_days',
                           'statz.cached_stats.1_month',
                           'statz.partner.cached_stats.24_hours',
                           'statz.partner.cached_stats.7_days',
                           'statz.partner.cached_stats.1_month',
                           'statz.partner-ios.cached_stats.24_hours',
                           'statz.partner-ios.cached_stats.7_days',
                           'statz.partner-ios.cached_stats.1_month',
                           'statz.partner-android.cached_stats.24_hours',
                           'statz.partner-android.cached_stats.7_days',
                           'statz.partner-android.cached_stats.1_month',
                           'tools.disabled_popular_offers' ]
      (keys + distributed_keys).each do |key|
        data = Mc.get(key)
        f = File.open("tmp/mc_#{key}", 'w')
        f.write(Marshal.dump(data))
        f.close
      end
      true
    end
    
    def self.restore_state
      keys = [ 'statz.last_updated.24_hours',
               'statz.last_updated.7_days',
               'statz.last_updated.1_month',
               'statz.partner.last_updated.24_hours',
               'statz.partner.last_updated.7_days',
               'statz.partner.last_updated.1_month',
               'statz.partner-ios.last_updated.24_hours',
               'statz.partner-ios.last_updated.7_days',
               'statz.partner-ios.last_updated.1_month',
               'statz.partner-android.last_updated.24_hours',
               'statz.partner-android.last_updated.7_days',
               'statz.partner-android.last_updated.1_month',
               'money.cached_stats',
               'money.total_balance',
               'money.total_pending_earnings',
               'money.last_updated' ]
      distributed_keys = [ 'statz.cached_stats.24_hours',
                           'statz.cached_stats.7_days',
                           'statz.cached_stats.1_month',
                           'statz.partner.cached_stats.24_hours',
                           'statz.partner.cached_stats.7_days',
                           'statz.partner.cached_stats.1_month',
                           'statz.partner-ios.cached_stats.24_hours',
                           'statz.partner-ios.cached_stats.7_days',
                           'statz.partner-ios.cached_stats.1_month',
                           'statz.partner-android.cached_stats.24_hours',
                           'statz.partner-android.cached_stats.7_days',
                           'statz.partner-android.cached_stats.1_month',
                           'tools.disabled_popular_offers' ]
      Mc.cache.flush
      (keys + distributed_keys).each do |key|
        f = File.open("tmp/mc_#{key}", 'r')
        data = Marshal.restore(f.read)
        f.close
        if distributed_keys.include?(key)
          Mc.distributed_put(key, data)
        else
          Mc.put(key, data)
        end
      end
      OfferCacher.cache_offer_stats
      OfferCacher.cache_offers
      Mc.cache_all
      true
    end
    
    def self.aggregate_all_stats
      cutoff = Time.now.utc.beginning_of_hour
      Offer.find_each(:conditions => ["last_stats_aggregation_time < ?", cutoff]) do |offer|
        Sqs.send_message(QueueNames::APP_STATS_HOURLY, offer.id)
      end
    end
    
    def self.all_stats_aggregated?
      cutoff = Time.now.utc.beginning_of_hour
      Offer.count(:conditions => ["last_stats_aggregation_time < ?", cutoff]) == 0
    end
    
    def self.advance_last_stats_aggregation_times
      last_aggregation_time = Time.now.utc.beginning_of_hour + 1.hour
      Offer.find_each(:conditions => ["last_stats_aggregation_time < ?", last_aggregation_time]) do |offer|
        offer.last_stats_aggregation_time = last_aggregation_time
        offer.save(false)
      end
    end
    
    def self.queue_recount_stats_jobs
      end_time = Time.now.utc.beginning_of_hour.to_i
      start_time = end_time - 1.hour
      Offer.find_each do |offer|
        message = { :offer_id => offer.id, :start_time => start_time, :end_time => end_time }.to_json
        Sqs.send_message(QueueNames::RECOUNT_STATS, message)
      end
    end
  end
  
end
