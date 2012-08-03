module Offer::Optimization

  def for_caching
    run_callbacks(:cache)
    clear_association_cache
    self
  end

  def optimization_override!(offer_hash={}, log_info=true)
    # Add more recalculation for other fields when necessary
    new_show_rate = recalculate_show_rate(offer_hash, log_info)
    optimized_info = {:show_rate => new_show_rate}
    optimized_info[:rank_score] = offer_hash['rank_score'] if offer_hash['rank_score']

    optimized_info.each do |key, value|
      self.send("#{key}=", value)
    end
  end

end
