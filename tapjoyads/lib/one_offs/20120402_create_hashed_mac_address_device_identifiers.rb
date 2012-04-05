class OneOffs
  # This should be called for each of the device domains (NUM_DEVICES_DOMAINS).
  def self.create_hashed_mac_address_device_identifiers(domain_num)
    num_processed = 0
    Device.select(:domain_name => "devices_#{domain_num}") do |device|
      if device.mac_address.present?
        begin
          hashed_mac = Digest::SHA1.hexdigest(Device.formatted_mac_address(device.mac_address))
          device_identifier = DeviceIdentifier.new(:key => hashed_mac)
          unless device_identifier.udid == device.key
            device_identifier.udid = device.key
            device_identifier.save!
          end
        rescue Exception => ex
          puts "#{ex}, retrying"
          sleep 0.2
          retry
        end
      end
      num_processed += 1
      puts "#{Time.zone.now} - #{num_processed} devices processed so far. Iterating on domain number: #{domain_num}" if num_processed % 1000 == 0
    end
  end
end
