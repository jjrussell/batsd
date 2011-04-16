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

  def self.set_tapjoy_enabled_on_currencies
    Currency.find_each do |c|
      # TODO - probably should have some logic here to determine whether it should actually be enabled
      c.update_attribute(:tapjoy_enabled, true)
    end
  end

end
