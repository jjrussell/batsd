class OneOffs
  def self.migrate_gamer_devices
    Gamer.scoped(:include => :gamer_devices, :conditions => 'gamers.udid is not null and gamer_devices.id is null').each do |gamer|
      device = Device.new(:key => gamer.udid)
      gamer_device = gamer.gamer_devices.build(:device => device)
      gamer_device.save!
    end
  end
end
