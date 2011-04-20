class OneOffs

  def self.migrate_publisher_users(select_options = {})
    count = 0
    already_migrated = 0
    num_migrated = 0
    num_skipped = 0
    time = Benchmark.realtime do
      PublisherUserRecord.select(select_options) do |pur|
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

  def self.set_tapjoy_currency_enabled
    Partner.find_each do |p|
      if p.id != 'e9a6d51c-cef9-4ee4-a2c9-51eef1989c4e' && p.currencies.count > 0
        p.update_attribute(:tapjoy_currency_enabled, true)
      end
    end
  end

  def self.generate_secret_keys_for_apps
    App.find_each do |app|
      app.send(:generate_secret_key)
      app.save!
    end
  end

  def self.apple_data(domain_num)
    count = 0
    domain_name = "rewards_#{domain_num}"
    counts = {}
    start = Time.zone.now.beginning_of_year
    finish = start + 3.months
    Reward.select(:domain_name => domain_name, :where => "created >= '#{start.to_i}' AND created < '#{finish.to_i}'") do |r|
      count += 1
      puts "#{Time.zone.now.to_s(:db)} - looked at #{count} rewards" if count % 1000 == 0
      next unless r.udid =~ /^[a-f0-9]{40}$/
      counts[r.udid] ||= 0
      counts[r.udid] += 1
    end
    b = S3.bucket(BucketNames::TAPJOY)
    b.put("apple_data/#{domain_name}.json", counts.to_json)
    counts
  end

end
