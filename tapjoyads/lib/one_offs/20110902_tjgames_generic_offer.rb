class OneOffs
  def self.set_app_run_for_tapjoy_games
    udids = Gamer.find(:all, :conditions => ['udid is not ?', nil]).map(&:udid).uniq
    udids.each do |udid|
      Device.new(:key => udid).set_app_run!(TAPJOY_GAMES_REGISTRATION_OFFER_ID, {})
    end
  end
end
