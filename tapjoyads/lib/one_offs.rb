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
  
  def self.create_advertiser_udids_lists_for_august
    total = Offer.count
    count = 0
    start_time = Time.zone.parse("2010-08-01").to_i
    finish_time = Time.zone.parse("2010-08-11").to_i
    Offer.find_each do |offer|
      count += 1
      puts "#{count} / #{total} : #{offer.id}"
      message = { :offer_id => offer.id, :start_time => start_time, :finish_time => finish_time }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      sleep(2)
    end
  end
  
  def self.create_advertiser_udids_lists_for_month(month)
    return unless month < 8 and month > 0 # [1..7]
    total = Offer.count
    count = 0
    start_time = Time.zone.parse("2010-0#{month}-01").to_i
    finish_time = Time.zone.parse("2010-0#{month + 1}-01").to_i
    Offer.find_each do |offer|
      count += 1
      puts "#{count} / #{total} : #{offer.id}"
      message = { :offer_id => offer.id, :start_time => start_time, :finish_time => finish_time }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      sleep(2)
    end
  end
  
end
