class OneOffs
  
  def self.check_syntax
    Rails::Initializer.run(:load_application_classes)
    true
  end
  
  # returns a hash of yesterday's store_click counts by country for the given advertiser_app_id
  def self.installs_by_country_for_advertiser_app_id(advertiser_app_id, start_date, end_date)
    st = Time.zone.parse(start_date).to_f.to_s
    et = Time.zone.parse(end_date).end_of_day.to_f.to_s
    counts = {}
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:where => "advertiser_app_id = '#{advertiser_app_id}' and created >= '#{st}' and created < '#{et}'", :domain_name => "rewards_#{i}") do |reward|
       country = reward.country
       counts[country] = ((counts[country] || 0) + 1)
      end
    end
    counts
  end
  
  def self.get_hourly_new_users_by_partner(filename, partner_id, start_date, end_date)
    file = File.open(filename, 'w')
    file.puts "app, month, day, hour, new_users, paid_installs"
    App.find_all_by_partner_id(partner_id).each do |app|
      as = Appstats.new app.id, {
        :granularity => :hourly, 
        :start_time => Time.parse(start_date), 
        :end_time => Time.parse(end_date), 
        :stat_types => ['new_users','paid_installs'], 
        :include_labels => :true, 
        :type => :granular
        } 
      
      day = Time.parse(start_date)
      last = Time.parse(end_date)
      c = 0
      begin
        24.times do |hour|
          file.puts "#{app.name}, #{day.month}, #{day.day}, #{hour}, #{as.stats['new_users'][c]}, #{as.stats['paid_installs'][c]}"
          c += 1
        end
        day = day + 1.day        
      end while day != last            
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
  
  def self.merge_doodle_buddy_vgs(filename)
    holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    
    map = {}
    VirtualGood.select :where => "app_id = '#{holiday_id}'" do |hvg|
      rvg = VirtualGood.select :where => "app_id = '#{regular_id}' and name = '^^TAPJOY_ESCAPED^^#{CGI::escape(hvg.name)}'"
      next if rvg.nil? or rvg[:items].first.nil?
      map[hvg.key] = rvg[:items].first.key
      puts "#{hvg.key}, #{rvg[:items].first.key}"
    end
    
    ok = 0
    NUM_POINT_PURCHASES_DOMAINS.times do |i|
      PointPurchases.select :where => "itemName() like '%#{holiday_id}' and added_to_regular is null", :domain_name => "point_purchases_#{i}" do |hpp|
        PointPurchases.transaction :key => hpp.key.gsub(holiday_id, regular_id) do |rpp|
          rpp.points = rpp.points + hpp.points
          hpp.virtual_goods.each do |vg|
            #puts "VG not found: #{vg[0]}" unless map[vg[0]]
            #puts "VG #{vg[0]} maps to #{map[vg[0]]}" unless map[vg[0]].nil?
            unless map[vg[0]].nil?
              ok += 1 
              puts "#{ok} ok" if ok % 100 == 0
              rpp.add_virtual_good(map[vg[0]])
            end
          end
          puts "#{hpp.key} => #{rpp.key}"
        end  
        hpp.put('added_to_regular',Time.zone.now.to_i.to_s)
        hpp.save!  
      end
    end
    
  end
  
  
  def self.award_doodle_buddy_holiday_earnings(date)
    holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    
    created_date = Time.parse(date).to_f.to_s
    
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select :domain_name => "rewards_#{i}", :where => "publisher_app_id = '#{holiday_id}' and created > '#{created_date}' and added_to_db is null" do |r|
        PointPurchases.transaction :key => "#{r.udid}.#{regular_id}" do |pp|
          pp.points = pp.points + r.currency_reward
          puts "Added money to #{r.udid}"
        end
        r.put('added_to_db',Time.now.to_f.to_s)
        r.save!
      end
    end
    
  end
  
  def self.get_monthly_data_by_partner(partner_id, year, month)
      
    month_start = Time.utc(year, month, 01)
    
    total_revenue = 0
    total_spend = 0
    
    puts "App, Revenue, Spend"
    
    Offer.find_all_by_partner_id(partner_id).each do |offer|
      s = Appstats.new(offer.id, {:granularity => :daily, :start_time => month_start, :end_time => month_start.end_of_month})
      revenue = s.stats['rewards_revenue'].sum + s.stats['display_revenue'].sum
      spend = -s.stats['installs_spend'].sum
      total_revenue += revenue
      total_spend += spend
      puts "#{offer.name.gsub(',','_')}, $#{(revenue/100.0)}, $#{(spend/100.0)}" if revenue != 0 or spend != 0
    end
    
    puts "Total, $#{(total_revenue/100.0)}, $#{(total_spend/100.0)}"
    
    
  end
  
  def self.get_monthly_actives(filename)
    file = File.open(filename, 'w')
    partners = {}
    count = 0
    Currency.find_each do |c|
      (4..10).each do |month|
        month_start = Time.utc(2010,month,01)
        maus = 0
        begin
          s = Appstats.new(c.app.id, {:granularity => :daily, :start_time => month_start, :end_time => month_start.end_of_month})
          maus = s.stats['monthly_active_users'].sum
        rescue 
          maus = 0
        end
        file.puts "#{month}, app, #{c.app.id}, #{c.app.name}, #{maus}"
        partners[c.partner_id] = {} if partners[c.partner_id].nil?
        partners[c.partner_id][month] = 0 if partners[c.partner_id][month].nil?
        partners[c.partner_id][month] += maus
        count += 1
        puts "Wrote #{count} apps data to file" if count % 100 == 0
      end
    end
    partners.keys.each do |p|
      name = Partner.find(p).name
      partners[p].keys.sort.each do |m|
        file.puts "#{m}, partner, #{p}, #{name}, #{partners[p][m]}"
      end
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
        device = Device.new :key => udid
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
        puts "#{Time.zone.now.to_s(:db)} - finished #{counter} UDIDs, #{new_udids} new (global), #{existing_udids} existing (global), #{app_new_udids} new (per app), #{app_existing_udids} existing (per app)" if counter % 1000 == 0
      end
    end
    puts "finished importing #{counter} UDIDs in #{time.ceil} seconds"
    puts "new UDIDs (global): #{new_udids}"
    puts "existing UDIDs (global): #{existing_udids}"
    puts "new UDIDs (per app): #{app_new_udids}"
    puts "existing UDIDs (per app): #{app_existing_udids}"
  end

  def self.grab_groupon_udids
    date = Time.zone.parse('2010-10-04').to_date
    end_date = Time.zone.now.to_date
    
    while date < end_date
      puts "Running #{date}"
      self.grab_groupon_udids_for_date(date)
      
      date += 1.day
    end
  end

  def self.grab_groupon_udids_for_date(date)
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    outfile = open("groupon_udids_#{date.to_s}.txt", 'w')
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      s3_name = "web-request-#{date.to_s}-#{num}.sdb"
      next unless bucket.key(s3_name).exists?
      puts "Found #{s3_name}"
      
      gzip_file = open("#{s3_name}.gz", 'w')
      S3.s3.interface.get(bucket.full_name, s3_name) do |chunk|
        gzip_file.write(chunk)
      end
      gzip_file.close
      `gunzip -f #{s3_name}.gz`
      
      domain = open(s3_name)
      domain.each do |line|
        wr = WebRequest.deserialize(line)
        if wr.app_id == '192e6d0b-cc2f-44c2-957c-9481e3c223a0' && wr.path.include?('new_user')
          outfile.write(wr.udid)
          outfile.write("\n")
        end
      end
      domain.close
      `rm #{s3_name}`
    end
    
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
             'money.last_updated',
             'money.daily_cached_stats',
             'money.daily_last_updated' ]
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
             'money.last_updated',
             'money.daily_cached_stats',
             'money.daily_last_updated' ]
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
    Offer.cache_featured_offers
    Offer.cache_enabled_offers
    true
  end

  def self.convert_stats_to_new_format
    count = 0
    Stats.select do |stat|
      if stat.key =~ /^campaign/
        stat.delete_all
      else
        begin
          stat.save!
        rescue
          puts "Save failed, retrying. #{stat.key}"
          sleep(1)
          retry
        end
      end
      puts "#{Time.zone.now.to_s(:db)}: #{count}" if count % 1000 == 0
      count += 1
    end
  end

end
