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

  def self.tapulous_sucks
    partners = Set.new(['32b4c167-dd33-40c6-9b3e-2020427b6f4c'])
    pub_user_ids = {}
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:domain_name => "rewards_#{i}", :where => "offer_id = 'a3980ac5-7d33-43bc-8ba1-e4598c7ed279' AND advertiser_amount = '-3400' AND created > '1302739200' AND displayer_amount = '0'") do |r|
        puts r.id
        r.advertiser_amount = -34
        r.publisher_amount = r.publisher_amount / 100
        r.tapjoy_amount = 34 - r.publisher_amount
        r.put('tapulous_overspend', '1')
        r.save!
        Conversion.connection.execute("UPDATE conversions SET advertiser_amount = #{r.advertiser_amount}, publisher_amount = #{r.publisher_amount}, tapjoy_amount = #{r.tapjoy_amount} WHERE id = '#{r.id}'")
        app = App.find_in_cache(r.publisher_app_id, true)
        partners << app.partner
        pub_user_ids[r.publisher_app_id] ||= []
        pub_user_ids[r.publisher_app_id] << r.publisher_user_id
      end
    end
    puts "done fixing rewards and conversions"
    
    partners.each do |p|
      p.reset_balances
    end
    puts "done fixing partner balances"
    
    (pub_user_ids.keys + ['a3980ac5-7d33-43bc-8ba1-e4598c7ed279']).each do |offer_id|
      message = { :offer_id => offer_id, :start_time => '1302746400', :end_time => '1302757200' }.to_json
      Sqs.send_message(QueueNames::RECOUNT_STATS, message)
    end
    puts "done queuing recount stats jobs"
    
    b = S3.bucket(BucketNames::TAPJOY)
    b.put('tapulous_sucks', pub_user_ids.to_json)
    
    pub_user_ids
  end

end
