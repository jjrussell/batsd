module Enumerable

  def mean
    self.sum / self.length.to_f
  end

  def variance
    avg = self.mean
    sum = self.inject(0) { |acc,i| acc + (i - avg)**2 }
    (1 / self.length.to_f * sum)
  end

  def standard_deviation
    Math.sqrt(self.variance)
  end

end