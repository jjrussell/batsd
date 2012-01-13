class OneOffs

  def self.create_device_identifiers_queue
    Sqs.create_queue("CreateDeviceIdentifiers", 5)
  end

  def self.create_device_identifier_domains
    NUM_DEVICE_IDENTIFIER_DOMAINS.times do |i|
      SimpledbResource.create_domain("device_identifiers_#{i}")
    end
  end

  # This should be called for each of the device domains (NUM_DEVICES_DOMAINS).
  def self.populate_device_identifiers(domain_num)
    num_processed = 0

    # This is a long running task, which will iterate over every existing device,
    # and create corresponding entries in the device_identifiers table.
    Device.select(:domain_name => "devices_#{domain_num}") do |device|
      begin
        new_mac_address = device.mac_address.present? ? device.mac_address.downcase.gsub(/:/,"") : nil
        if new_mac_address != device.mac_address
          device.put('mac_address', new_mac_address)
          device.save!
        end
        device.create_identifiers!
        num_processed += 1
        puts "#{Time.zone.now} - #{num_processed} devices processed so far. Iterating on domain number: #{domain_num}" if num_processed % 1000 == 0
      rescue Exception => ex
        puts "#{ex}, retrying"
        sleep 0.2
        retry
      end
    end
  end
end
