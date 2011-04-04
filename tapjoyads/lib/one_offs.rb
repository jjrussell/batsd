class OneOffs


  def self.aggregate_all_global_stats(date = nil)
    date ||= Time.zone.parse('November 10, 2009')
    while date < Time.zone.now
      puts "#{Time.zone.now}: starting aggregation for #{date}"
      StatsAggregation.aggregate_daily_group_stats(date)
      puts "#{Time.zone.now}: done aggregating for #{date}"
      date += 1.day
    end
    puts 'all finished!'
    puts "*" * 80
  end
  
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
  
  ##
  # Finds users that have run TapZoo on a given date that also have run TextFree at some point.
  def self.find_textfree_tapzoo_overlap_udids(date)
    tapzoo_app_id = 'c3fc6075-57a9-41d1-b0ee-e1c0cbbe4ef3'
    textfree_app_id = '6b69461a-949a-49ba-b612-94c8e7589642'
    bucket = S3.bucket(BucketNames::WEB_REQUESTS)
    outfile = open("tmp/tapzoo_textfree_udids_#{date.to_s}.txt", 'w')
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      s3_name = "web-request-#{date.to_s}-#{num}.sdb"
      next unless bucket.key(s3_name).exists?
      puts "Found #{s3_name}"
      
      gzip_file = open("tmp/#{s3_name}.gz", 'w')
      S3.s3.interface.get(bucket.full_name, s3_name) do |chunk|
        gzip_file.write(chunk)
      end
      gzip_file.close
      `gunzip -f 'tmp/#{s3_name}.gz'`
      
      domain = open("tmp/#{s3_name}")
      domain.each do |line|
        wr = WebRequest.deserialize(line)
        if wr.app_id == tapzoo_app_id && wr.path.include?('new_user')
          d = Device.find(wr.udid)
          if d.has_app(textfree_app_id)
            outfile.puts(wr.udid)
          end
        end
      end
      domain.close
      `rm 'tmp/#{s3_name}'`
    end
    
    outfile.close
  end
  
  def self.analyze_clicks(udid_filename, advertiser_app_id)
    file = File.open(udid_filename, 'r')
    outfile = File.open("#{udid_filename}.output.csv", 'w')
    not_found = 0
    total = 0
    file.each do |line|
      line.strip!
      udid = line.split(',')[0].gsub(/\W/, '')
      click = Click.find("#{udid}.#{advertiser_app_id}")
      outfile.write(line)
      if click.present?
        outfile.write(",#{click.publisher_app_id},#{click.source},#{click.country}")
      else
        not_found += 1
      end
      total += 1
      puts "#{Time.zone.now}: Total: #{total}, not_found: #{not_found}" if total % 1000 == 0
      outfile.write("\n")
    end
    outfile.close
    puts "Done!: Total: #{total}, not_found: #{not_found}"
  end

  def self.add_udids_to_admin_devices
    android_devices = [
        { :udid => '359116032048366',                          :device_label => 'Hwan-Joon HTC G2' },
        { :udid => '355031040123271',                          :device_label => 'Kai Nexus S'      },
        { :udid => 'a00000155c5106',                           :device_label => 'Linda Droid'      },
        { :udid => '354957031929568',                          :device_label => 'Linda Nexus One'  },
        { :udid => '355031040294361',                          :device_label => 'Linda Nexus S'    },
        { :udid => 'a100000d982193',                           :device_label => 'Matt Evo'         },
        { :udid => 'a100000d9833c5',                           :device_label => 'Stephen Evo'      },
        { :udid => 'a000002256c234',                           :device_label => 'Steve Droid X'    },
    ]
    ios_devices = [
        { :udid => 'ade749ccc744336ad81cbcdbf36a5720778c6f13', :device_label => 'Amir iPhone'      },
        { :udid => 'c73e730913822be833766efffc7bb1cf239d855a', :device_label => 'Ben iPhone'       },
        { :udid => '9ac478517b48da604bdb9fc15a3e48139d59660d', :device_label => 'Christine iPhone' },
        { :udid => 'f3de44744a306beb47407b9a23cd97d9fe03339a', :device_label => 'Christine iPad'   },
        { :udid => '12910a92ab2917da99b8e3c785136af56b08c271', :device_label => 'Chris iPhone'     },
        { :udid => '20c56f0606cc34f56525bb9ca03dcd0a43d70c60', :device_label => 'Dan iPad'         },
        { :udid => '473acbc76dd573784fc803dc0c694aec8fa35d49', :device_label => 'Dan iPhone'       },
        { :udid => '5c46e034cd005e5f2b08501820ecb235b0f13f33', :device_label => 'Hwan-Joon iPhone' },
        { :udid => 'cb76136c7362206edad3d485a1dbd51bee52cd1f', :device_label => 'Hwan-Joon iPad'   },
        { :udid => 'c163a3b343fbe6d04f9a8cda62e807c0b407f533', :device_label => 'Hwan-Joon iTouch' },
        { :udid => 'cb7907c2a762ea979a3ec38827a165e834a2f7f9', :device_label => 'Johnny iPhone'    },
        { :udid => '36fa4959f5e1513ba1abd95e68ad40b75b237f15', :device_label => 'Kai iPad'         },
        { :udid => '5eab794d002ab9b25ee54b4c792bbcde68406b57', :device_label => 'Katherine iPhone' },
        { :udid => '4b910938aceaa723e0c0313aa7fa9f9d838a595e', :device_label => 'Linda iPad'       },
        { :udid => '820a1b9df38f3024f9018464c05dfbad5708f81e', :device_label => 'Linda iPhone'     },
        { :udid => '5941f307a0f88912b0c84e075c833a24557a7602', :device_label => 'Marc iPad'        },
        { :udid => 'dda01be21b0937efeba5fcda67ce20e99899bb69', :device_label => 'Matt iPad2'       },
        { :udid => 'b4c86b4530a0ee889765a166d80492b46f7f3636', :device_label => 'Ryan iPhone'      },
        { :udid => 'f0910f7ab2a27a5d079dc9ed50d774fcab55f91d', :device_label => 'Ryan iPad'        },
        { :udid => 'cb662f568a4016a5b2e0bd617e53f70480133290', :device_label => 'Stephen iPad'     },
        { :udid => 'c1bd5bd17e35e00b828c605b6ae6bf283d9bafa1', :device_label => 'Stephen iTouch'   },
        { :udid => '2e75bbe138c85e6dc8bd8677220ef8898f40a1c7', :device_label => 'Sunny iPhone'     },
        { :udid => '21569fd0d308bfc576380903e8ba5a5f2fb9a01c', :device_label => 'Tammy iPad'       },
    ]
    android_devices.each do |device|
      AdminDevice.new(:udid => device[:udid], :description => device[:device_label], :platform => 'android').save
    end

    ios_devices.each do |device|
      AdminDevice.new(:udid => device[:udid], :description => device[:device_label], :platform => 'iphone').save
    end
  end
  
  def self.migrate_publisher_users
    time = Benchmark.realtime do
      count = 0
      already_migrated = 0
      num_migrated = 0
      num_skipped = 0
      PublisherUserRecord.select do |pur|
        count += 1
        pub_user = PublisherUser.new(:key => pur.key)
        unless pub_user.new_record?
          already_migrated += 1
          next
        end
        
        pur.get('udid', :force_array => true).each do |udid|
          pub_user.udids = udid
        end
        unless pub_user.changed?
          num_skipped += 1
          next
        end
        
        begin
          pub_user.save!
          num_migrated += 1
        rescue Exception => e
          puts "failed to save #{pub_user.key}, retrying..."
          sleep(0.2)
          retry
        end
        
        puts "#{Time.zone.now.to_s(:db)} - count: #{count}, num_migrated: #{num_migrated}, already_migrated: #{already_migrated}, num_skipped: #{num_skipped}" if count % 1000 == 0
      end
    end
    
    puts "finished #{count} PublisherUserRecords in #{time / 3600} hours"
    puts "num_migrated: #{num_migrated}"
    puts "already_migrated: #{already_migrated}"
    puts "num_skipped: #{num_skipped}"
  end
  
end
