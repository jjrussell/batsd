class OneOffs

  def self.downcase_admin_device_udids
    AdminDevice.find_each do |admin_device|
      admin_device.udid = admin_device.udid.downcase
      admin_device.save! if admin_device.changed?
    end
  end

end
