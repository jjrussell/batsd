class OneOffs
  def self.set_last_run_time_for_link_facebook_offer
    GamerDevice.all.each do |gamer_device|
      gamer = Gamer.find_by_id(gamer_device.gamer_id)
      if gamer && gamer.facebook_id
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
