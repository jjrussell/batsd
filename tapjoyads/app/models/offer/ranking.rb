module Offer::Ranking

  def self.included(base)
    base.class_eval do
      attr_writer :rank_score
      before_save :calculate_ranking_fields
    end
  end

  def calculate_ranking_fields
    return if Rails.env.test? # We need to be seeding the test environment with enabled offers for these calculations to work
    stats                       = OfferCacher.get_offer_stats
    self.normal_conversion_rate = (stats[:cvr_std_dev] == 0) ? 0 : (conversion_rate - stats[:cvr_mean]) / stats[:cvr_std_dev]
    self.normal_price           = (stats[:price_std_dev] == 0) ? 0 : (price - stats[:price_mean]) / stats[:price_std_dev]
    self.normal_avg_revenue     = (stats[:avg_revenue_std_dev] == 0) ? 0 : (avg_revenue - stats[:avg_revenue_mean]) / stats[:avg_revenue_std_dev]
    self.normal_bid             = (stats[:bid_std_dev] == 0) ? 0 : (bid_for_ranks - stats[:bid_mean]) / stats[:bid_std_dev]
    self.over_threshold         = bid >= 40 ? 1 : 0
    self.rank_boost             = rank_boosts.active.sum(:amount)
  end

  def calculate_ranking_fields!
    calculate_ranking_fields
    save!
  end

  def precache_rank_scores
    rank_scores = {}
    CurrencyGroup.find_each do |currency_group|
      score = currency_group.precache_weights.keys.inject(0) { |sum, key| sum + (currency_group.precache_weights[key] * send(key)) }
      rank_scores[currency_group.id] = score
    end
    rank_scores
  end

  def precache_rank_score_for(currency_group_id)
    precache_rank_scores[CurrencyGroup::DEFAULT_ID]
  end

  def rank_score
    @rank_score ||= (precache_rank_score_for(CurrencyGroup::DEFAULT_ID) || 0)
  end

  def bid_for_ranks
    [ bid, 500 ].min
  end

  def avg_revenue
    conversion_rate * bid_for_ranks
  end

  def percentile
    self.conversion_rate = is_paid? ? (0.05 / (0.01 * price)) : 0.50 if conversion_rate == 0
    calculate_ranking_fields
    percentile_group_id = CurrencyGroup.find_by_name('percentile').id
    offers = OfferList.new(:type => percentile_type).offers.reject { |o| o.id == id }
    100 * offers.select { |o| precache_rank_score_for(percentile_group_id) >= o.precache_rank_score_for(percentile_group_id) }.length / offers.length
  end

  def percentile_type
    return Offer::VIDEO_OFFER_TYPE if video_offer?

    if featured?
      if rewarded?
        Offer::FEATURED_OFFER_TYPE
      else
        Offer::NON_REWARDED_FEATURED_OFFER_TYPE
      end
    else
      if rewarded?
        Offer::DEFAULT_OFFER_TYPE
      else
        Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      end
    end
  end

  def is_reasonable_rank_boost?
    rank_boost <= RankBoost::RANK_SCORE_THRESHOLD
  end

  def override_rank_score!
    if (rank_boost > 0 && publisher_app_whitelist.present? && is_reasonable_rank_boost?) || rank_boost < 0
      self.rank_score = rank_boost
    end
  end
end
