class String
  def to_version_array
    split(".").collect(&:to_i)
  end
  
  def version_greater_than_or_equal_to?(other_version)
    (to_version_array <=> other_version.to_version_array) >= 0
  end
  
  def normalize_device_type
    if self =~ /iphone/i
      'iphone'
    elsif self =~ /ipod/i
      'itouch'
    elsif self =~ /ipad/i
      'ipad'
    elsif self =~ /android/i
      'android'
    else
      nil
    end
  end
end