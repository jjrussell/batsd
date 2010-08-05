class OneOffs
  
  def self.check_syntax
    true
  end
  
  def self.get_udids(app_id, output_file)
    file = File.open(output_file, 'w')
    20.times do |i|
      counter = 0
      SimpledbResource.select(:domain_name => "device_app_list_#{i}", :where => "`app.#{app_id}` != ''") do |device|
        organic_paid = "organic"
        click = StoreClick.new(:key => "#{device.key}.#{app_id}")
        organic_paid = "paid" if click && click.get('installed')
        file.puts "#{device.key}, #{organic_paid}"
        counter += 1
        puts "Finished #{counter}" if counter % 100 == 0
      end
      puts "Completed device_app_list_#{i}"
    end
    file.close
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
  
  ##
  # Reads all archived store-clicks, and prints out a file the udid's of all installs for a given app.
  def self.get_ppi_udids_from_archive(app_id, output_file_name, start_date = '2009-11-18', end_date = nil)
    end_date = end_date.nil? ? Time.zone.now.to_date : Time.zone.parse(end_date).to_date
    
    output_file = File.open(output_file_name, 'w')
    gzip_file_name = 'tmp/store-clicks.sdb.gz'
    file_name = 'tmp/store-clicks.sdb'
    
    bucket = S3.bucket(BucketNames::STORE_CLICKS)
    
    date = Time.zone.parse(start_date)
    date -= 1.day
    
    count = 0
    
    loop do
      date += 1.day
      break if date > end_date
      
      key = "store-click_#{date.to_date.to_s(:db)}.sdb"
      puts key
      next unless bucket.key(key).exists?
      
      puts "Processing #{key}"
      
      begin
        gzip_file = open(gzip_file_name, 'w')
        S3.s3.interface.get(BucketNames::STORE_CLICKS, key) do |chunk|
          gzip_file.write(chunk)
        end
        gzip_file.close
      rescue Exception => e
        `rm #{gzip_file_name}`
        puts "Error reading from s3: #{e}. Retrying"
        sleep(0.1)
        retry
      end
      `gunzip -f #{gzip_file_name}`
      
      file = open(file_name)
      items = []
      file.each do |line|
        click = StoreClick.deserialize(line)
        if click.advertiser_app_id == app_id && click.installed_at
          udid = click.key.split('.')[0]
          output_file.puts("#{udid},#{click.installed_at.to_s(:db)}")
          count +=1
        end
      end
      
      puts "#{count} total installs"

      `rm #{file_name}`
    end
    output_file.close
    
  end
  
  def self.give_all_clicks_currency(app_id, date)
    #give everyone who clicked to app_id after date currency (and charge the advertiser)
    
    count = 0
    StoreClick.select(:where => "advertiser_app_id = '#{app_id}' and installed is null and click_date > '#{Time.zone.parse(date).to_f.to_s}'") do |click|
      #just add to conversion tracking queue
      count += 1
      
      p "Sent #{count} messages to the queue" if count % 1000 == 0
      message = {:udid => click.key.split('.')[0], :app_id => app_id, 
            :install_date => click.click_date.to_f.to_s}.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
    
  end

  def self.create_udid_list_for_all_advertisers(month)
    return unless month < 9 and month > 0 # [1..8]
    count = Offer.count
    index = 0
    Offer.find_each do |offer|
      start_time = Time.zone.parse("2010-0#{month}-01")
      finish_time = 1.month.since(start_time)
      # because we are running this in August
      if (month == 8)
        finish_time = 1.day.ago(Time.zone.now).beginning_of_day
      end

      message = {:offer_id => offer.id, :start_time => start_time.to_f, :finish_time => finish_time.to_f}.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      p "#{index += 1} / #{count} (#{offer.name rescue "?"} : #{offer.id}) #{start_time.strftime("%m-%d")} - #{finish_time.strftime("%m-%d")}"

      sleep(5) #don't want to overwhelm the job servers
    end
  end
  
  def self.import_udids_into_reward
    total_clicks = 0
    total_rewards = 0
    total_rewards_modified = 0
    
    StoreClick.select do |click|
      total_clicks += 1
      if click.reward_key
        total_rewards += 1
        reward = Reward.new :key => click.reward_key
        unless reward.udid
          reward.udid = click.udid
          reward.serial_save
          total_rewards_modified += 1
        end
      end
      
      if total_clicks % 1000 == 0
        puts "#{Time.zone.now.to_s(:db)}: Clicks: #{total_clicks}, Rewards: #{total_rewards}, Rewards modified: #{total_rewards_modified}"
      end
    end
    
    puts "Complete. #{Time.zone.now.to_s(:db)}: Clicks: #{total_clicks}, Rewards: #{total_rewards}, Rewards modified: #{total_rewards_modified}"
  end
  
  def self.import_udids_into_reward_from_archive(start_date = '2009-11-18', end_date = nil)
    end_date = end_date.nil? ? Time.zone.now.to_date : Time.zone.parse(end_date).to_date
    
    gzip_file_name = 'tmp/store-clicks.sdb.gz'
    file_name = 'tmp/store-clicks.sdb'
    
    bucket = S3.bucket(BucketNames::STORE_CLICKS)
    
    date = Time.zone.parse(start_date)
    date -= 1.day
    
    count = 0
    
    total_clicks = 0
    total_rewards = 0
    total_rewards_modified = 0
    
    loop do
      date += 1.day
      break if date > end_date
      
      key = "store-click_#{date.to_date.to_s(:db)}.sdb"
      puts key
      next unless bucket.key(key).exists?
      
      puts "Processing #{key}"
      
      begin
        gzip_file = open(gzip_file_name, 'w')
        S3.s3.interface.get(BucketNames::STORE_CLICKS, key) do |chunk|
          gzip_file.write(chunk)
        end
        gzip_file.close
      rescue Exception => e
        `rm #{gzip_file_name}`
        puts "Error reading from s3: #{e}. Retrying"
        sleep(0.1)
        retry
      end
      `gunzip -f #{gzip_file_name}`
      
      file = open(file_name)
      items = []
      file.each do |line|
        total_clicks += 1
        click = StoreClick.deserialize(line)
        if click.reward_key
          total_rewards += 1
          reward = Reward.new :key => click.reward_key
          unless reward.udid
            reward.udid = click.udid
            reward.serial_save
            total_rewards_modified += 1
          end
        end
        
        if total_clicks % 1000 == 0
          puts "#{Time.zone.now.to_s(:db)}: Clicks: #{total_clicks}, Rewards: #{total_rewards}, Rewards modified: #{total_rewards_modified}"
        end
        
      end
      
      puts "Complete. #{Time.zone.now.to_s(:db)}: Clicks: #{total_clicks}, Rewards: #{total_rewards}, Rewards modified: #{total_rewards_modified}"

      `rm #{file_name}`
    end
    
  end
  
  def self.populate_daily_stats
    total_stats = 0
    total_app_stats = 0
    
    Stats.select do |stat|
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
