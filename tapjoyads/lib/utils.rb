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
  
  def self.reset_memcached
    save_memcached_state
    restore_memcached_state
  end

  def self.save_memcached_state
    keys = [ 'statz.last_updated.24_hours',
             'statz.last_updated.7_days',
             'statz.last_updated.1_month',
             'money.cached_stats',
             'money.total_balance',
             'money.total_pending_earnings',
             'money.last_updated' ]
    distributed_keys = [ 'statz.cached_stats.24_hours',
                         'statz.cached_stats.7_days',
                         'statz.cached_stats.1_month',
                         'tools.disabled_popular_offers' ]
    (keys + distributed_keys).each do |key|
      data = Mc.get(key)
      f = File.open("tmp/mc_#{key}", 'w')
      f.write(Marshal.dump(data))
      f.close
    end
    true
  end

  def self.restore_memcached_state
    keys = [ 'statz.last_updated.24_hours',
             'statz.last_updated.7_days',
             'statz.last_updated.1_month',
             'money.cached_stats',
             'money.total_balance',
             'money.total_pending_earnings',
             'money.last_updated' ]
    distributed_keys = [ 'statz.cached_stats.24_hours',
                         'statz.cached_stats.7_days',
                         'statz.cached_stats.1_month',
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
    Offer.cache_offers
    Mc.cache_all
    true
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
  
end