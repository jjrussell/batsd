class OneOffs
  # This should be called for each of the device domains (NUM_DEVICES_DOMAINS).
  # Do not run in production, we will different machines for this.
  def self.create_sha1_udid_device_identifiers(domain_num)
    num_processed = 0
    Device.select(:domain_name => "devices_#{domain_num}") do |device|
      begin
        device_identifier = DeviceIdentifier.new(:key => Digest::SHA1.hexdigest(device.key))
        unless device_identifier.udid == device.key
          device_identifier.udid = device.key
          device_identifier.save!
        end
      rescue Exception => ex
        puts "#{ex}, retrying"
        sleep 0.2
        retry
      end
      num_processed += 1
      puts "#{Time.zone.now} - #{num_processed} devices processed so far. Iterating on domain number: #{domain_num}" if num_processed % 10 == 0
    end
  end
end
