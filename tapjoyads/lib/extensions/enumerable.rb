module Enumerable

  def mean
    sum / length.to_f
  end

  def variance
    return 0 if length == 0
    avg = mean
    sum = inject(0) { |acc,i| acc + (i - avg)**2 }
    (1 / length.to_f * sum)
  end

  def standard_deviation
    Math.sqrt(variance)
  end

end
