class OneOffs
  
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
  
end
