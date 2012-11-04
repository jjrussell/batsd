class String
  def to_version_array
    split(".").collect(&:to_i)
  end

  def to_library_version
    LibraryVersion.new(self)
  end

  def version_greater_than?(other_version)
    to_version_array > other_version.to_version_array
  end

  def version_greater_than_or_equal_to?(other_version)
    to_version_array >= other_version.to_version_array
  end

  def version_less_than?(other_version)
    to_version_array < other_version.to_version_array
  end

  def version_less_than_or_equal_to?(other_version)
    to_version_array <= other_version.to_version_array
  end

  def version_equal_to?(other_version)
    to_version_array == other_version.to_version_array
  end

  def matz_silly_hash
    key = each_byte.inject(0) { |sum,c| ((sum * 65599).signed_overflow + c.ord).signed_overflow }

    (key + (key >> 5)).signed_overflow
  end

  def ip_to_i
    split(".").inject(0) { |s, p| (s << 8) + p.to_i }
  end

  def to_a
    [self]
  end

  def id
    self.object_id
  end
end
