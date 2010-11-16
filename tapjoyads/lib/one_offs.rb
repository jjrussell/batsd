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
    50.times do |i|
      items = Reward.select(:where => "advertiser_app_id = '#{advertiser_app_id}' and created >= '#{st}' and created <= '#{et}'", :domain_name => "rewards_#{i}")[:items]
      items.each do |item|
        country = item.get('country')
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
    10.times do |i|
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
    
    50.times do |i|
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
  
  def self.get_monthly_actives(filename)
    file = File.open(filename, 'w')
    partners = {}
    count = 0
    Currency.find_each do |c|
      (4..10).each do |month|
        month_start = Time.utc(2010,month,01)
        maus = 0
        begin
          s = Appstats.new(c.app.id, {:type => :sum, :start_time => month_start, :end_time => month_start.end_of_month})
          maus = s.stats['monthly_active_users'].first
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

  def self.add_partners_to_chimp
    partners = []
    publishers = []

    Partner.using_slave_db do
      Partner.slave_connection.execute("BEGIN")
      Partner.find_each(:include => ['users', 'offers']) do |partner|
        partners << partner unless partner.non_managers.blank?
      end
      errors = MailChimp.add_partners(partners)
    end
  ensure
    Partner.using_slave_db do
      Partner.slave_connection.execute("COMMIT")
    end
  end

  def self.update_partner_data_from_currencies
    inconsistent_count = 0
    file = File.open('inconsistent_currencies', 'w')
    
    Partner.find_each do |partner|
      size = partner.currencies.size
      print "#{partner.name} (#{partner.id}): #{size} currencies... "
      
      if size > 0
        matches = true
        installs_money_share_set = Set.new
        disabled_partners_set = Set.new
        
        partner.currencies.each do |currency|
          installs_money_share_set << currency.installs_money_share
          disabled_partners_set << currency.get_disabled_partner_ids
        end
        
        if installs_money_share_set.size == 1 && disabled_partners_set.size == 1
          partner.installs_money_share = installs_money_share_set.first
          partner.disabled_partners = disabled_partners_set.first.to_a.join(';')
          partner.save!
          puts 'Success.'
        else
          inconsistent_count += 1
          puts "Fail. Inconsistent values. Details follow:"
          file.puts("#{partner.name} (#{partner.id})")
          partner.currencies.each do |currency|
            puts "  #{currency.name} (#{currency.id})"
            puts "    installs_money_share: #{currency.installs_money_share}"
            puts "    disabled_partners: #{currency.disabled_partners}"
            file.puts "  #{currency.name} (#{currency.id})"
            file.puts "    installs_money_share: #{currency.installs_money_share}"
            file.puts "    disabled_partners: #{currency.disabled_partners}"
          end
        end
      else
        puts ''
      end
    end
    file.close
    puts "Finished. #{inconsistent_count} partners with inconsistent currencies."
  end
  
  def self.set_initial_offer_discounts
    Partner.find_each do |partner|
      order = partner.orders.scoped(:order => 'created_at DESC', :conditions => [ 'created_at >= ?', 3.months.ago ]).first
      order.send :create_spend_discount if order
    end
  end
  
  def self.set_initial_bids
    Offer.find_each do |offer|
      offer.bid = offer.payment
      offer.save_without_validation
    end
  end

  def self.reset_memcached
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
    data = {}
    (keys + distributed_keys).each do |key|
      data[key] = Mc.get(key)
    end
    
    Mc.cache.flush
    
    data.each do |k, v|
      if distributed_keys.include?(k)
        Mc.distributed_put(k, v)
      else
        Mc.put(k, v)
      end
    end
    
    Offer.cache_featured_offers
    Offer.cache_enabled_offers
    true
  end

  def self.migrate_ratings_to_use_reward_value
    Offer.find_each(:conditions => "item_type = 'RatingOffer'") do |offer|
      offer.reward_value = offer.bid
      offer.bid = 0
      offer.payment = 0
      offer.save!
    end
  end

end
