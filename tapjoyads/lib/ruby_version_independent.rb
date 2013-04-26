class RubyVersionIndependent
  def self.hash(string)
    key = string.each_byte.inject(0) { |sum,c| ((sum * 65599).signed_overflow + c.ord).signed_overflow }

    (key + (key >> 5)).signed_overflow
  end
end
