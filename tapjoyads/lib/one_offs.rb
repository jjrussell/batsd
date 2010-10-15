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
  
  def self.get_hourly_new_users_by_partner(filename, partner_id, start_date, end_date)
    return if Time.now(end_date) < Time.now(start_date)
    file = File.open(filename, 'w')
    file.puts "app, month, day, hour, new_users, paid_installs"
    App.find_by_partner_id(partner_id) do |app|
      as = Appstats.new app.id, {
        :granularity => :hourly, 
        :start_time => Time.parse(start_date), 
        :end_time => Time.parse(end_date), 
        :stat_types => ['new_users','paid_installs'], 
        :include_labels => :true, 
        :type => :granular} 
      
      day = Time.parse(start_date)
      last = Time.parse(end_date)
      c = 0
      begin
        24.times do |hour|
          file.puts "#{app.name}, #{day.month}, #{day.day}, #{hour}, #{as.stats['new_users'][c]}, #{as.stats['paid_installs'][c]}"
          c += 1
        end
        day = day + 1.day        
      while day != last            
    end
    file.close
  end
  
  def self.get_click_udids(filename, app_id)
    file = File.open(filename, 'w')
    50.times do |i|
      count = 0
      items = {}
      
      begin
        SimpledbResource.select(:domain_name => "clicks_#{i}", :where => "advertiser_app_id = '#{app_id}'") do |click|
          udid = click.key.split('.')[0]
          installed = click.get('installed_at') != nil
          items[udid] = "#{click.get('clicked_at')}, #{installed}"
        count += 1
        end
      rescue 
        puts "Error in select after #{count} on clicks_#{i}"
        count = 0
        items = {}
        retry
      end
      
      items.keys.each do |item|
        file.puts "#{item}, #{items[item]}"
      end
      
      puts "Wrote #{count} lines from click_#{i}"
    end
    file.close  
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
        app_list = Device.new :key => udid
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
  
  def self.populate_partner_names
    App.find_each(:conditions => "store_id is not null and store_id != ''") do |app|
      puts ""
      puts "Fetching data for app: #{app.name} (#{app.id}). Store id: #{app.store_id}"
      begin
        data = AppStore.fetch_app_by_id(app.store_id, app.platform)
        raise "Data is nil" if data.nil?
      rescue Exception => e
        puts "Error fetching data from app store: #{e}."
        print "Retry? [Y/n]"
        answer = STDIN.gets
        if answer =~ /^(n|no)$/i
          next
        else
          app = app.reload
          retry
        end
      end
      
      if app.partner.name.nil?
        puts "Partner name was missing in our system. Now is: '#{data[:publisher]}'"
        app.partner.name = data[:publisher]
        app.partner.save!
        puts "Partner name updated."
      elsif app.partner.name == data[:publisher]
        puts "Partner name is: '#{data[:publisher]}' in both our system and app store."
        puts "No change made."
      else
        puts "Partner name is: '#{app.partner.name}' in our system, but '#{data[:publisher]}' on app store."
        print "Update partner name from app store? [y/N] "
        answer = STDIN.gets
        if answer =~ /^(y|yes)$/i
          app.partner.name = data[:publisher]
          app.partner.save!
          puts "Partner name updated."
        else
          puts "No change made."
        end
      end
    end
  end
  
  def self.migrate_device_app_list(num)
    count = 0
    failed_to_migrate_count = 0
    race_condition_count = 0
    record_already_migrated_count = 0
    total_count = DeviceLookup.count(:where => "app_list = '#{num}'")
    start_time = Time.zone.now
    puts "starting to migrate #{total_count} devices from device_app_list_#{num}"
    DeviceLookup.select(:where => "app_list = '#{num}'", :retries => 1000) do |item|
      count += 1
      begin
        device = Device.new(:key => item.key)
      rescue
        failed_to_migrate_count += 1
        item.put('failed_to_migrate', 'true')
        item.serial_save({:updated_at => false})
        next
      end
      if device.pulled_from_device_app_list
        begin
          device.serial_save(:catch_exceptions => false, :expected_attr => { 'updated-at' => nil })
        rescue ExpectedAttributeError => e
          race_condition_count += 1
          next
        rescue
          sleep 1
          puts "retrying to save device: #{device.key}"
          retry
        end
      else
        record_already_migrated_count += 1
      end
      if count % 1000 == 0
        elapsed_seconds = Time.zone.now - start_time
        elapsed_hours = (elapsed_seconds / 3600).round_with_precision(2)
        rate = (count / elapsed_seconds).round_with_precision(2)
        estimated_hours_remaining = ((total_count - count) / rate / 3600).round_with_precision(2)
        puts "finished migrating #{count} in #{elapsed_hours} hours at a rate of #{rate} per second - hours remaining: #{estimated_hours_remaining}, failed to migrate: #{failed_to_migrate_count}, already migrated: #{record_already_migrated_count}, race conditions encountered: #{race_condition_count}"
      end
    end
    elapsed_seconds = Time.zone.now - start_time
    elapsed_hours = (elapsed_seconds / 3600).round_with_precision(2)
    rate = (count / elapsed_seconds).round_with_precision(2)
    puts "finished migrating #{count} in #{elapsed_hours} hours at a rate of #{rate} per second - failed to migrate: #{failed_to_migrate_count}, already migrated: #{record_already_migrated_count}, race conditions encountered: #{race_condition_count}"
  end
  
end
