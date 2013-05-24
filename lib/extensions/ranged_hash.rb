#Currently being used for CurrencySale. There is an issue
#with have potential 'overlapping' keys since this uses
#a range as a hash key. CurrencySale has a specific use case
#that you can never have overlapping times for a sale, therefore,
#it will never have overlapping keys. If you plan on using for
#other cases (i.e. potential overlapping ranges) you are going
#to have a bad time.
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
