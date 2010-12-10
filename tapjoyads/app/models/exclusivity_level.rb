class ExclusivityLevel
  TYPES = %w( ThreeMonth SixMonth NineMonth )
  attr_reader :months, :discount, :name
end

class ThreeMonth < ExclusivityLevel
  def initialize
    @months = 3
    @discount = 5
    @name = "3 Months"
  end
end

class SixMonth < ExclusivityLevel
  def initialize
    @months = 6
    @discount = 10
    @name = "6 Months"
  end
end

class NineMonth < ExclusivityLevel
  def initialize
    @months = 9
    @discount = 15
    @name = "9 Months"
  end
end

class InvalidExclusivityLevelError < RuntimeError; end
