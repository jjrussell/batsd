class OneOffs
  def self.copy_publisher_user_ids_to_device(domain_number)
    count = 0

    PublisherUser.select(:domain_name => "publisher_users_#{domain_number}") do |publisher_user|
      puts "#{Time.zone.now.to_s}, #{domain_number}, #{count}" if count % 1000 == 0
      count += 1

      app_id = publisher_user.key.split('.')[0]
      user_id = publisher_user.key.split('.', 2)[1]
      next if app_id.blank? || user_id.blank?

      publisher_user.udids.each do |udid|
        device = Device.new(:key => udid)

        parsed_publisher_user_ids = device.publisher_user_ids
        next if parsed_publisher_user_ids[app_id] == user_id

        parsed_publisher_user_ids[app_id] = user_id
        device.publisher_user_ids = parsed_publisher_user_ids

        begin
          device.save!
        rescue
          puts "device save failed for UDID: #{udid}   retrying..."
          sleep 0.2
          retry
        end
      end
    end
  end
end
