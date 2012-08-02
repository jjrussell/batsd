class OneOffs
  def self.create_temporary_device_domains
    NUM_TEMPORARY_DEVICE_DOMAINS.times do |i|
      SimpledbResource.create_domain("temporary_devices_#{i}")
    end
  end
end
