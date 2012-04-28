class Delayed

  def self.show?
    Time.zone.now >= Date.new(2012, 5, 1)
  end

end
