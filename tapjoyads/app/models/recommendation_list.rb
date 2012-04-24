class RecommendationList
  Offer # This class caches Offers, so the Offer model must be loaded

  attr_reader :offers

  MINIMUM = 7

  def initialize(options = {})
    @device      = options[:device]
    @device_type = options[:device_type]
    @geoip_data  = options[:geoip_data] || {}
    @os_version  = options[:os_version]
    @store_ids   = Set.new

    @offers = RecommendationList.for_device(@device.id).reject { |offer| recommendation_reject?(offer) }
    @offers |= RecommendationList.for_app(@device.last_app_run).reject { |offer| recommendation_reject?(offer) } if @offers.length < MINIMUM
    @offers |= RecommendationList.most_popular.reject { |offer| recommendation_reject?(offer) } if @offers.length < MINIMUM
  end

  def apps
    @offers[0...MINIMUM].collect { |rec_hash| CachedApp.new(rec_hash[:offer], :explanation => explanation_string(rec_hash)) }
  end

  class << self

    def cache_all
      Recommender.cache_all_active_recommenders
      cache_most_popular_offers
    end

    def cache_most_popular_offers
      offers = []
      Recommender.instance.most_popular.each do |recommendation_hash|
        recommendation_hash[:offer] = Offer.find_in_cache(recommendation_hash[:recommendation])
        next if recommendation_hash[:offer].nil?
        offers << recommendation_hash
      end
      Mc.distributed_put("s3.recommendations.with_offers.most_popular.#{Offer.acts_as_cacheable_version}", offers)
    end

    def most_popular
      Mc.distributed_get("s3.recommendations.with_offers.most_popular.#{Offer.acts_as_cacheable_version}") || []
    end

    def for_app(app_id)
      Mc.get_and_put("s3.recommendations.with_offers.by_app.#{app_id}.#{Offer.acts_as_cacheable_version}", false, 1.day) do
        offers = []
        Recommender.instance.for_app(app_id).each do |recommendation_hash|
          recommendation_hash[:offer] = Offer.find_in_cache(recommendation_hash[:recommendation])
          next if recommendation_hash[:offer].nil?
          offers << recommendation_hash
        end
        offers.any? ? offers : nil
      end || []
    end

    def for_device(device_id)
      Mc.get_and_put("s3.recommendations.with_offers.by_device.#{device_id}.#{Offer.acts_as_cacheable_version}", false, 1.day) do
        offers = []
        Recommender.instance.for_device(device_id).each do |recommendation_hash|
          recommendation_hash[:offer] = Offer.find_in_cache(recommendation_hash[:recommendation])
          next if recommendation_hash[:offer].nil?
          offers << recommendation_hash
        end
        offers.any? ? offers : nil
      end || []
    end

  end

  private

  def recommendation_reject?(recommendation_hash)
    offer = recommendation_hash[:offer]
    rejected = offer.store_id_for_feed.blank?
    rejected ||= @store_ids.include?(offer.store_id_for_feed)
    rejected ||= offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version)
    @store_ids << offer.store_id_for_feed unless rejected

    rejected
  end

  def explanation_string(recommendation_hash)
    exp = recommendation_hash[:explanation]
    return nil unless exp.present?
    return "Popular App" if exp == "Popular App"
    app = App.find_in_cache(exp)
    app.present? ? app.name : nil
  end

end
