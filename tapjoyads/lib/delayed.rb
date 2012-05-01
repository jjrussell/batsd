class Delayed

  START_TIME = Date.new(2012, 5, 2)
  DURATION = 1.week

  def self.show?
    Time.zone.now >= START_TIME
  end

  def self.show_in_duration?
    Time.zone.now >= START_TIME && Time.zone.now <= START_TIME + DURATION
  end

end
