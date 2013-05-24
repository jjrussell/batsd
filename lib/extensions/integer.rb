class Integer
  def signed_overflow
    (self + 2147483648) % 4294967296 - 2147483648
  end
end
