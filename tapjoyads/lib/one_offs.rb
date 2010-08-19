class OneOffs
  
  def self.check_syntax
    Rails::Initializer.run(:load_application_classes)
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
  
  def self.archive_store_clicks
    Benchmark.realtime do
      count = 0
      files = {}
      SimpledbResource.select(:domain_name => 'store-click') do |click|
        count += 1
        puts "#{Time.zone.now.to_s(:db)} - Finished backing up #{count} clicks." if count % 1000 == 0
        
        next unless Click.new(:key => click.key, :load_from_memcache => false).is_new
        next unless click.get('click_date')
        
        click_date_str = Time.zone.at(click.get('click_date').to_f).strftime("%Y-%m-%d")
        files[click_date_str] = File.open("tmp/store-click_#{click_date_str}.sdb", 'w') if files[click_date_str].nil?
        
        files[click_date_str].puts(click.serialize)
      end
      
      files.values.each do |file|
        file.close
      end
    end
  end
  
end
