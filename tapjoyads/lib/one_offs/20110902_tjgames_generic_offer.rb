class OneOffs
  def self.set_last_run_time_for_tapjoy_games
    udids = Gamer.find(:all, :conditions => ['udid is not ?', nil]).map(&:udid).uniq
    udids.each do |udid|
      d = Device.new(:key => udid)
      d.set_last_run_time(TAPJOY_GAMES_REGISTRATION_OFFER_ID)
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
