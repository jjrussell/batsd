module Offer::Optimization

  def for_caching
    run_callbacks(:cache)
    clear_association_cache
    self
  end

end
