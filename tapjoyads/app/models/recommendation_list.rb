class RecommendationList
  Offer # This class caches Offers, so the Offer model must be loaded

  attr_reader :offers

  MINIMUM           = 7

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
    @offers[0...MINIMUM].collect { |o| CachedApp.new(o) }
  end

  class << self

    def cache_all
      Recommender.cache_all_active_recommenders
      cache_most_popular_offers
    end

    def cache_most_popular_offers
      offers = []
      Recommender.instance.most_popular.each do |recommendation, weight|
        begin
          offers << Offer.find_in_cache(recommendation)
        rescue ActiveRecord::RecordNotFound => e
          next
        end
      end
      offers.compact!
      Mc.distributed_put('s3.recommendations.offers.most_popular', offers)
    end


    def most_popular
      Mc.distributed_get('s3.recommendations.offers.most_popular') || []
    end

    def for_app(app_id)
      Mc.get_and_put("s3.recommendations.offers.by_app.#{app_id}", false, 1.day) do
        offers = []
        Recommender.instance.for_app(app_id).each do |recommendation, weight|
          begin
            offers << Offer.find_in_cache(recommendation)
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        offers.compact!

        offers.any? ? offers : nil
      end || []
    end

    def for_device(device_id)
      Mc.get_and_put("s3.recommendations.offers.by_device.#{device_id}", false, 1.day) do
        offers = []
        Recommender.instance.for_device(device_id).each do |recommendation, weight|
          begin
            offers << Offer.find_in_cache(recommendation)
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        offers.compact!

        offers.any? ? offers : nil
      end || []
    end

  end

  private

  def recommendation_reject?(offer)
    rejected = @store_ids.include?(offer.store_id_for_feed) || offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version)
    @store_ids << offer.store_id_for_feed unless rejected || offer.store_id_for_feed.blank?

    rejected
  end

end
