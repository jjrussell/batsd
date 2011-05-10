class Hash
  def strip_zero_arrays!
    each do |key, value|
      delete(key) if value.uniq == [0]
    end
  end
end
