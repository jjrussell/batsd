class Array
  def weighted_rand(weights)
    selection = Kernel::rand * weights.sum
    max_weight = 0
    zip(weights).each do |element, weight|
      max_weight += weight
      return element if selection < max_weight
    end
    nil
  end
end
