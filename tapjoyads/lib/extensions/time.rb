##
# Modifies the Time object to add a few additional beginning_of, and end_of methods.

class Time
  def beginning_of_hour
    self.change(:min => 0, :sec=> 0, :usec => 0)
  end

  def end_of_hour
    self.beginning_of_hour + 1.hour - 1.second
  end

  def beginning_of_minute
    self.change(:sec => 0, :usec => 0)
  end

  def end_of_minute
    self.beginning_of_minute + 1.minute - 1.second
  end
end
