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

  # enable beta website for individual users
  def self.add_beta(options={})
    if options[:uid]
      user = User.find_by_id(options[:uid])
    elsif options[:pid]
      user = Partner.find_by_id(options[:pid]).users.first
    elsif options[:email]
      user = User.find_by_email(options[:email])
    elsif options.is_a?(String)
      user = User.find_by_email(options)
    else
      puts "Usage:"
      puts ">> OneOffs.enable_beta('hc5duke@gmail.com')"
      puts ">> OneOffs.enable_beta(:uid => user_id)"
      puts ">> OneOffs.enable_beta(:pid => partner_id)"
      return
    end
    if user.nil?
      puts "Unable to find user with #{options.inspect}"
    else
      beta = UserRole.find_by_name("beta_website")
      user.user_roles << beta unless user.user_roles.include?(beta)
      puts "[[ Success! ]]\n"
      return user
    end
  end
end
