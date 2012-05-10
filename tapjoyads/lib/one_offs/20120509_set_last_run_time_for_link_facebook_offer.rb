class OneOffs
  def self.set_last_run_time_for_link_facebook_offer
    udids = Gamer.find(:all, :conditions => ['udid is not ?', nil]).map(&:udid).uniq
    udids.each do |udid|
      d = Device.new(:key => udid)
      d.set_last_run_time(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID)
      begin
        d.save!
      rescue
        puts "save failed for #{d.key}, retrying..."
        sleep 0.2
        retry
      end
    end
  end
end
