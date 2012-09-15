module Offer::Optimization

  AUDITION_FACTORS = {
    :low =>1,
    :medium_low => 2,
    :medium => 3,
    :medium_high => 4,
    :high => 5,
    :very_high => 10
  }

  DEFAULT_AUDITION_FACTOR = AUDITION_FACTORS[:medium]

  def for_caching
    run_callbacks(:cache)
    clear_association_cache
    self
  end

  def optimization_override(offer_hash={}, log_info=true)
    optimized_info = {}

    override_show_rate(optimized_info, offer_hash, log_info)
    override_rank_score(optimized_info, offer_hash, log_info)

    optimized_info.each do |key, value|
      self.send("#{key}=", value)
    end

    self
  end

  def override_show_rate(optimized_info, offer_hash={}, log_info=true)
    new_show_rate = recalculate_show_rate(offer_hash, log_info)
    optimized_info[:show_rate] = new_show_rate
  end

  def override_rank_score(optimized_info, offer_hash={}, log_info=true)
    optimized_info[:rank_score] = offer_hash['rank_score'] if offer_hash['rank_score']

    if rank_boost != 0
      offer_hash_rank_score = offer_hash['rank_score'] || 0
      if rank_boost > 0
        if publisher_app_whitelist.present? && is_reasonable_rank_boost?
            optimized_info[:rank_score] = (rank_boost + offer_hash_rank_score).floor
        end
      else
        optimized_info[:rank_score] = (rank_boost + offer_hash_rank_score).floor
      end
    end
  end
end
