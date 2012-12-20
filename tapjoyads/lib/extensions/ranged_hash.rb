class RangedHash
  def initialize(hash={})
    @ranges = hash
  end

  def [](key)
    @ranges.detect { |range, value| range.include?(key) }.try(:last)
  end

  def []=(key, value)
    @ranges[key] = value
  end
end
