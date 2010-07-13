class OneOffs
  
  def self.check_syntax
    true
  end
  
  def self.import_conversions
    Benchmark.realtime do
      file = File.open('tmp/conversions.txt', 'r')
      line_counter = 0
      file.each_line do |line|
        line_counter += 1
        
        # the first 2 lines are headers
        if line_counter < 3
          next
        end
        
        vals = line.split(' ', 11)
        
        # check to see if this line is a complete conversion record and not just a summary/blank line
        unless vals.length == 11
          puts "*** weird line ***"
          puts line
          next
        end
        
        if Conversion.find_by_id(vals[0].downcase).nil?
          c = Conversion.new
          c.id = vals[0].downcase
          c.reward_id = vals[7].downcase unless vals[7] == 'NULL'
          c.advertiser_offer = Offer.find_by_item_id(vals[2].downcase) unless vals[2] == 'NULL'
          c.publisher_app_id = vals[1].downcase
          c.advertiser_amount = vals[4].to_i
          c.publisher_amount = vals[3].to_i
          c.tapjoy_amount = vals[5].to_i + vals[6].to_i
          c.reward_type = 999
          c.created_at = Time.parse(vals[10] + ' CST').utc
          c.updated_at = Time.parse(vals[10] + ' CST').utc
          begin
            c.save!
          rescue Exception => e
            puts "*** retrying *** #{e.message}"
            retry
          end
        end
        puts "#{Time.zone.now} - finished #{line_counter} conversions" if line_counter % 1000 == 0
      end
      file.close
    end
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
  
  def self.calculate_partner_balances
    Benchmark.realtime do
      counter = 0
      Partner.find_each do |p|
        counter += 1
        p.recalculate_balances(true)
        puts "finished #{counter} partners" if counter % 100 == 0
      end
    end
  end
  
  def self.requeue_rewards(start_time, interval = 1.hour, num_intervals = 1)
    queue = RightAws::SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN)
    num_intervals.times do
      puts "queueing from #{start_time.to_s(:db)} to #{(start_time + interval).to_s(:db)}..."
      counter = 0
      time = Benchmark.realtime do
        Reward.select(:where => "(type='offer' or type='install') and created >= '#{start_time.to_f}' and created < '#{(start_time + interval).to_f}'") do |reward|
          counter += 1
          reward.delete('sent_money_txn')
          queue.send_message(reward.serialize(:attributes_only => true))
        end
      end
      start_time += interval
      puts "completed #{counter} in #{time.ceil} seconds."
    end
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
  
  def self.change_offer_ids_to_offer_item_ids
    Benchmark.realtime do
      counter = 0
      Offer.find(:all, :select => "id, item_id").each do |offer|
        counter += 1
        Conversion.connection.execute("UPDATE conversions SET advertiser_offer_id = '#{offer.item_id}' WHERE advertiser_offer_id = '#{offer.id}'")
        Offer.connection.execute("UPDATE offers SET id = '#{offer.item_id}' WHERE id = '#{offer.id}'")
        puts "#{Time.zone.now.to_s(:db)} - completed #{counter} offers" if counter % 100 == 0
      end
    end
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
        udid = line.gsub("\n", "").downcase
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
  
  def self.fix_fluent_conversions
    send_currency_queue = RightAws::SqsGen2.new.queue(QueueNames::SEND_CURRENCY)
    send_money_txn_queue = RightAws::SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN)
    StoreClick.select(:where => "publisher_user_record_id like '9dfa6164-9449-463f-acc4-7a7c6d7b5c81.%'") do |click|
      click.put('publisher_user_record_id', click.get('publisher_user_record_id').gsub('9dfa6164-9449-463f-acc4-7a7c6d7b5c81.', ''))
      click.serial_save
      if click.installed
        reward = Reward.new(:key => click.get('reward_key'))
        if reward.get('publisher_app_id')
          puts "reward exists: #{reward.key}"
        else
          reward.put('type', 'install')
          reward.put('publisher_app_id', click.get('publisher_app_id'))
          reward.put('advertiser_app_id', click.get('advertiser_app_id'))
          reward.put('publisher_user_id', click.get('publisher_user_record_id'), {:cgi_escape => true})
          reward.put('advertiser_amount', click.get('advertiser_amount'))
          reward.put('publisher_amount', click.get('publisher_amount'))
          reward.put('currency_reward', click.get('currency_reward'))
          reward.put('tapjoy_amount', click.get('tapjoy_amount'))
          reward.put('offerpal_amount', click.get('offerpal_amount'))
          
          reward.serial_save
          
          message = reward.serialize(:attributes_only => true)
          
          puts "sending reward: #{reward.key} to sqs"
          
          send_currency_queue.send_message(message)
          send_money_txn_queue.send_message(message)
        end
      end
    end and true
  end
  
  ##
  # Reads all archived store-clicks, and prints out a file the udid's of all installs for a given app.
  def self.get_ppi_udids_from_archive(app_id, output_file_name, start_date = '2009-11-18', end_date = nil)
    end_date = end_date.nil? ? Time.zone.now.to_date : Time.zone.parse(end_date).to_date
    
    output_file = File.open(output_file_name, 'w')
    gzip_file_name = 'tmp/store-clicks.sdb.gz'
    file_name = 'tmp/store-clicks.sdb'
    
    s3 = RightAws::S3.new
    bucket = s3.bucket('store-clicks')
    
    date = Time.zone.parse(start_date)
    date -= 1.day
    
    count = 0
    
    loop do
      date += 1.day
      break if date > end_date
      
      key = "store-click_#{date.to_date.to_s(:db)}.sdb"
      puts key
      next unless RightAws::S3::Key.create(bucket, key).exists?
      
      puts "Processing #{key}"
      
      begin
        gzip_file = open(gzip_file_name, 'w')
        s3.interface.get(bucket.full_name, key) do |chunk|
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
  
  def self.populate_third_party_data
    Offer.find_each(:conditions => "item_type = 'App'") do |offer|
      offer.third_party_data = offer.item.store_id
      offer.save!
    end
    Offer.find_each(:conditions => "item_type = 'EmailOffer'") do |offer|
      offer.third_party_data = offer.item.third_party_id
      offer.save!
    end
  end
  
  def self.fix_missing_publisher_user_records_in_tap_resort
    file = File.open('tapresort_missing_users.txt', 'w')
    file.write('user_id,udid,currency_amount,original_conversion_date')

    queue = RightAws::SqsGen2.new.queue(QueueNames::SEND_CURRENCY)
    
    count = 0
    
    Reward.select(:where => "publisher_app_id = '41df65f0-593c-470b-83a4-37be66740f34' and publisher_user_id is null") do |reward|
      response = StoreClick.select(:where => "reward_key = '#{reward.key}'")
      if response[:items].size != 1
        puts "click not found for reward #{reward.key} (#{response[:items].size} clicks found)"
        next
      end
      
      click = response[:items][0]
      udid = click.key.split('.')[0]

      response = PublisherUserRecord.select(:where => "udid = '#{udid}' and itemName() like '41df65f0-593c-470b-83a4-37be66740f34.%'")
      if response[:items].size != 1
        puts "PublisherUserRecord not found for reward #{reward.key} (#{response[:items].size} records found)"
        next
      end
      
      record = response[:items][0]
      user_id = record.key.split('.')[1]
      
      if user_id != udid
        puts "user_id != udid: #{user_id} != #{udid} for reward: #{reward.key}"
        next
      end
      
      if reward.get('sent_currency')
        puts "Already sent currency for reward: #{reward.key}"
        next
      end
      
      reward.put('publisher_user_id', user_id)
      reward.serial_save
      
      message = reward.serialize(:attributes_only => true)
      queue.send_message(message)
      
      file.write("#{user_id},#{udid},#{reward.get('currency_reward')},#{reward.get('created')}\n")
      count += 1
      
      puts "#{count}: Found user_id: #{user_id} for reward: #{reward.key}"
    end
    file.close
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
  
  def self.fix_point_purchases
    total = 0
    num_wrong = 0
    num_mismatch = 0
    num_malformed = 0
    
    10.times do |dnum|
      puts "point_purchases_#{dnum}"
      PointPurchases.select(:domain_name => "point_purchases_#{dnum}") do |pp|
        unless pp.key =~ /\./
          num_malformed += 1
          pp.delete_all
        end
        
        total += 1
        if pp.key.hash % 10 != dnum
          num_wrong += 1
          real_pp = PointPurchases.new :key => pp.key
          if pp.points != real_pp.points || pp.virtual_goods != real_pp.virtual_goods
            puts "MISMATCH: #{pp.key}, #{pp.points}, #{real_pp.points}"
            real_pp.points = real_pp.points + pp.points
            real_pp.virtual_goods = pp.virtual_goods.merge(real_pp.virtual_goods)
            real_pp.serial_save
            num_mismatch += 1
          end
          # Merge complete. Delete the extraneous pp.
          pp.delete_all
        end
        puts "Num mismatch: #{num_mismatch}, Num wrong: #{num_wrong}, num_malformed: #{num_malformed},total: #{total}. Current domain: point_purchases_#{dnum}"
      end
    end
  end
  
end
