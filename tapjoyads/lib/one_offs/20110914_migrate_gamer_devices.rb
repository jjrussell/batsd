class OneOffs
  def self.migrate_gamer_devices
    Gamer.scoped(:conditions => 'udid is not null').each do |gamer|
      device = Device.new(:key => gamer.udid)
      gamer_device = gamer.gamer_devices.build(:device_id => device.id, :product => device.product)
      gamer_device.save!
    end
  end
end
