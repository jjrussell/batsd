class OneOffs
  def self.set_app_run_for_tapjoy_games
    tjgames_id = 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
    udids = Gamer.find(:all, :conditions => ['udid is not ?', nil]).map(&:udid).uniq
    udids.each do |udid|
      Device.new(:key => udid).set_app_ran!(tjgames_id, {})
    end
  end
end
