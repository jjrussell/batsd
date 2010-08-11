class OneOffs
  
  def self.check_syntax
    true
  end
  
  # returns a hash of yesterday's store_click counts by country for the given advertiser_app_id
  def self.store_clicks_by_country_for_advertiser_app_id(advertiser_app_id)
    day = Time.zone.now.yesterday.to_date.to_s
    counts = {}
    0.upto(MAX_WEB_REQUEST_DOMAINS - 1) do |i|
      items = WebRequest.select(:where => "advertiser_app_id = '#{advertiser_app_id}' and path = 'store_click'", :domain_name => "web-request-#{day}-#{i}")[:items]
      items.each do |item|
        country = item.get('country')
        counts[country] = ((counts[country] || 0) + 1)
      end
    end
    counts
  end
  
  def self.import_udids(filename, app_id)
    counter = 0
    new_udids = 0
    existing_udids = 0
    app_new_udids = 0
    app_existing_udids = 0
    now = Time.zone.now.to_f.to_s
    file = File.open(filename, 'r')
    time = Benchmark.realtime do
      file.each_line do |line|
        counter += 1
        udid = line.gsub("\n", "").gsub('"', '').downcase
        app_list = DeviceAppList.new :key => udid
        app_list.is_new ? new_udids += 1 : existing_udids += 1
        if app_list.has_app app_id
          app_existing_udids += 1
        else
          app_new_udids += 1
          apps_hash = app_list.apps
          apps_hash[app_id] = now
          app_list.apps = apps_hash
          begin
            app_list.serial_save :catch_exceptions => false
          rescue
            puts "app_list save failed for UDID: #{udid}   retrying..."
            sleep 0.2
            retry
          end
        end
        puts "#{Time.zone.now.to_s(:db)} - finished #{counter} UDIDs, #{new_udids} new (global), #{existing_udids} existing (global), #{app_new_udids} new (per app), #{app_existing_udids} existing (per app)" if counter % 1000 == 0
      end
    end
    puts "finished importing #{counter} UDIDs in #{time.ceil} seconds"
    puts "new UDIDs (global): #{new_udids}"
    puts "existing UDIDs (global): #{existing_udids}"
    puts "new UDIDs (per app): #{app_new_udids}"
    puts "existing UDIDs (per app): #{app_existing_udids}"
  end
  
  def self.populate_daily_stats
    total_stats = 0
    total_app_stats = 0

    Stats.select(:where => "offerwall_views != ''") do |stat|
      total_stats += 1
      if stat.key =~ /app.\d{4}-\d{2}-\d{2}/
        total_app_stats += 1

        date, app_id = stat.parse_key

        daily_date_string = date.strftime('%Y-%m')
        daily_stat_row = Stats.new :key => "app.#{daily_date_string}.#{app_id}"
        daily_stat_row.populate_daily_from_hourly(stat, date.day - 1)
        daily_stat_row.serial_save
      end

      if total_stats % 1000 == 0
        puts "#{Time.zone.now.to_s(:db)}: Stats: #{total_stats}, App stats: #{total_app_stats}, Last operated on: #{stat.key}"
      end
    end

    puts "Complete. #{Time.zone.now.to_s(:db)}: Stats: #{total_stats}, App stats: #{total_app_stats}"
  end
  
end
