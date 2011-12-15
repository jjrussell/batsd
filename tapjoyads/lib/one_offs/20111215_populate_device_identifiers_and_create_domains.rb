class OneOffs
  def self.populate_device_identifiers_and_create_domains
    NUM_DEVICE_IDENTIFIERS_DOMAINS.times do |i|
      SimpledbResource.create_domain("device_identifiers_#{i}")
    end
    # This is a long running task, which will every existing device, and create corresponding
    # entries in the device_identifiers table.
    NUM_DEVICES_DOMAINS.times do |i|
      Device.select(:domain_name => "devices_#{i}") do |device|
        begin
          raise "Unable to create identifiers for device: #{device.id}" unless device.create_identifiers
        rescue Exception => ex
          puts "#{ex}, retrying"
          sleep 0.2
          retry
        end
      end
    end
  end
end
