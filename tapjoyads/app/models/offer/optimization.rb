module Offer::Optimization

  def for_caching
    run_callbacks(:cache)
    clear_association_cache
    self
  end

  def optimization_override(offer_hash={}, log_info=true)
    # Add more recalculation for other fields when necessary
    new_show_rate = recalculate_show_rate(offer_hash, log_info)
    ret_hash = {:show_rate => new_show_rate}
    ret_hash[:rank_score] = offer_hash[:rank_score] if offer_hash[:rank_score]
    ret_hash
  end

end
