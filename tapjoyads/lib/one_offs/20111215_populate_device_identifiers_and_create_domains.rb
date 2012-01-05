class OneOffs
  def self.populate_device_identifiers_and_create_domains
    NUM_DEVICE_IDENTIFIER_DOMAINS.times do |i|
      SimpledbResource.create_domain("device_identifiers_#{i}")
    end
    num_processed = 0

    # This is a long running task, which will every existing device, and create corresponding
    # entries in the device_identifiers table.
    NUM_DEVICES_DOMAINS.times do |i|
      Device.select(:domain_name => "devices_#{i}") do |device|
        begin
          raise "Unable to create identifiers for device: #{device.id}" unless device.create_identifiers
          num_processed += 1
          puts "#{Time.zone.now} - #{num_processed} devices processed so far. Iterating on domain number: #{i}" if num_processed % 1000 == 0
        rescue Exception => ex
          puts "#{ex}, retrying"
          sleep 0.2
          retry
        end
      end
    end
  end
end
