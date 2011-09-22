class OneOffs
  def self.migrate_gamer_devices
    Gamer.scoped(:conditions => 'udid').each do |gamer|
      device = Device.new(:key => gamer.udid)
      gamer_device = gamer.gamer_devices.build(:device => device)
      gamer_device.save!
    end
  end
end
