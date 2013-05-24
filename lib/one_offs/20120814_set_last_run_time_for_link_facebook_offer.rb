class OneOffs
  def self.set_last_run_time_for_link_facebook_offer
    Gamer.includes(:gamer_profile).where("gamer_profiles.facebook_id IS NOT NULL").find_each do |gamer|
      gamer.gamer_devices.each do |gamer_device|
        device = Device.new(:key => gamer_device.device_id)
        device.set_last_run_time(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID)
        begin
          device.save!
        rescue
          puts "save failed for #{d.key}, retrying..."
          sleep 0.2
          retry
        end
      end
    end
  end
end
