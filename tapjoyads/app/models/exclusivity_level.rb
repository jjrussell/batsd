class ExclusivityLevel
  TYPES = %w( ThreeMonth SixMonth TwelveMonth )
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
    @discount = 7
    @name = "6 Months"
  end
end

class TwelveMonth < ExclusivityLevel
  def initialize
    @months = 12
    @discount = 10
    @name = "12 Months"
  end
end

class InvalidExclusivityLevelError < RuntimeError; end