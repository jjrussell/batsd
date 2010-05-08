##
# Modifies the Time object to add a few additional beginning_of, and end_of methods.

class Time
  def beginning_of_hour
    self-(self.min).minutes-self.sec
  end
  def end_of_hour
    self.beginning_of_hour + 1.hour - 1.second
  end
  def beginning_of_minute
    self-self.sec
  end
  def end_of_minute
    self.beginning_of_minute + 1.minute - 1.second
  end
  def beginning_of(secs=5.minutes)
    return self if secs >= 1.day/2
    secs_today = self - self.beginning_of_day
    periods_today = (secs_today/secs).floor
    self.beginning_of_day + periods_today * secs
  end
  def end_of(secs=5.minutes)
    return self if secs >= 1.day/2
    beginning_of(secs) + secs - 1.second
  end
end
