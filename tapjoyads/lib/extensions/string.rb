class String
  def to_version_array
    split(".").collect(&:to_i)
  end

  def version_greater_than_or_equal_to?(other_version)
    (to_version_array <=> other_version.to_version_array) >= 0
  end

  def matz_silly_hash
    key = each_byte.inject(0) { |sum,c| ((sum * 65599).signed_overflow + c.ord).signed_overflow }

    (key + (key >> 5)).signed_overflow
  end
end
