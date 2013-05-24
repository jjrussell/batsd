class OfferCacher

  GROUP_SIZE            = 200
  OFFER_TYPES           = [ Offer::DEFAULT_OFFER_TYPE, Offer::FEATURED_OFFER_TYPE,
                            Offer::DISPLAY_OFFER_TYPE, Offer::NON_REWARDED_DISPLAY_OFFER_TYPE,
                            Offer::NON_REWARDED_FEATURED_OFFER_TYPE, Offer::VIDEO_OFFER_TYPE,
                            Offer::FEATURED_BACKFILLED_OFFER_TYPE, Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE,
                            Offer::NON_REWARDED_BACKFILLED_OFFER_TYPE
                          ]
  HIDE_REWARDED_OPTIONS = [ true, false ]
  PLATFORM_AND_DEVICE_TYPES = { '' => [''] }
  App::PLATFORMS.values.each do |platform|
    case platform
      when 'Android'
        PLATFORM_AND_DEVICE_TYPES[platform] = Offer::ANDROID_DEVICES
      when 'iOS'
        PLATFORM_AND_DEVICE_TYPES[platform] = Offer::APPLE_DEVICES
      when 'Windows'
        PLATFORM_AND_DEVICE_TYPES[platform] = Offer::WINDOWS_DEVICES
    end
  end

  class << self

    def cache_offers(save_to_s3 = false)
      Benchmark.realtime do
        offer_list = []
        cache_offers_prerejected(offer_list, Offer::CLASSIC_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.rewarded.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::DEFAULT_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.featured.rewarded.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::FEATURED_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.free.apps.rewarded.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::FEATURED_BACKFILLED_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.rewarded.for_offer_list.non_video_offers.for_display_ads.to_a
        cache_offers_prerejected(offer_list, Offer::DISPLAY_OFFER_TYPE, save_to_s3)

        displayed = offer_list = Offer.enabled_offers.nonfeatured.non_rewarded.free.apps.non_video_offers.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::NON_REWARDED_DISPLAY_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.featured.non_rewarded.free.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::NON_REWARDED_FEATURED_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.non_rewarded.free.apps.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE, save_to_s3)

        offer_list = (Offer.enabled_offers.nonfeatured.non_rewarded.for_offer_list.to_a + displayed).uniq
        cache_offers_prerejected(offer_list, Offer::NON_REWARDED_BACKFILLED_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.video_offers.for_offer_list.to_a
        cache_offers_prerejected(offer_list, Offer::VIDEO_OFFER_TYPE, save_to_s3)
      end
    end

    def cache_offers_prerejected(offers, type, save_to_s3 = false)
      offers.each { |o| o.run_callbacks(:cache); o.clear_association_cache }
      offer_list = offers.sort_by {|o| -(o.rank_score) }
      PLATFORM_AND_DEVICE_TYPES.each do |platform, device_types|
        HIDE_REWARDED_OPTIONS.each do |hide_rewarded_app_installs|
          device_types.each do |device_type|
            cache_offer_list("#{type}.#{platform}.#{hide_rewarded_app_installs}.#{device_type}", offer_list.reject { |o| o.precache_reject?(platform, hide_rewarded_app_installs, device_type)}, save_to_s3)
          end
        end
      end
    end

    def get_offers_prerejected(type, platform, hide_rewarded_app_installs, device_type)
      get_offer_list("#{type}.#{platform}.#{hide_rewarded_app_installs}.#{device_type}")
    end

    def cache_offer_list(key, offers, save_to_s3 = false)
      s3_key = "unsorted_offers.#{key}"
      mc_key = "s3.#{s3_key}.#{Offer.acts_as_cacheable_version}"
      bucket = S3.bucket(BucketNames::OFFER_DATA) if save_to_s3
      group = 0

      current_time = Time.now
      cached_offer_list = CachedOfferList.new

      post_processed_offer_with_rank = []
      compacted_offers = offers.compact.each_with_index do |offer, i|
        offer.cached_offer_list_id = cached_offer_list.id
        offer.cached_offer_list_type = 'native'
        post_processed_offer_with_rank << {'offer_id' => offer.id, 'rank' => (i + 1)}
      end

      compacted_offers.each_slice(GROUP_SIZE) do |offer_group|
        bucket.objects["#{s3_key}.#{group}"].write(:data => Marshal.dump(offer_group)) if save_to_s3
        Mc.distributed_put("#{mc_key}.#{group}", offer_group, false, 1.day)
        group += 1
      end

      bucket.objects["#{s3_key}.#{group}"].write(:data => Marshal.dump([])) if save_to_s3
      Mc.distributed_put("#{mc_key}.#{group}", [], false, 1.day)
      group += 1

      cached_offer_list.generated_at = current_time
      cached_offer_list.cached_at = current_time
      cached_offer_list.memcached_key = mc_key

      cached_offer_list.offer_list = post_processed_offer_with_rank
      cached_offer_list.cached_offer_type = 'native'
      cached_offer_list.save
      WebRequest.log_cached_offer_list(cached_offer_list)

      if save_to_s3
        while bucket.objects["#{s3_key}.#{group}"].exists?
          bucket.objects["#{s3_key}.#{group}"].delete
          Mc.distributed_delete("#{mc_key}.#{group}")
          group += 1
        end
      end
    end

    def get_offer_list(key)
      s3_key = "unsorted_offers.#{key}"
      mc_key = "s3.#{s3_key}.#{Offer.acts_as_cacheable_version}"
      group = 0
      offers = []

      loop do
        offer_group = Mc.distributed_get_and_put("#{mc_key}.#{group}", false, 1.day) do
          bucket = S3.bucket(BucketNames::OFFER_DATA)
          Marshal.safe_restore(bucket.objects["#{s3_key}.#{group}"].read)
        end
        offers |= offer_group
        break unless offer_group.length == GROUP_SIZE
        group += 1
      end

      offers
    end

    def cache_offer_stats
      offer_list = Offer.enabled_offers
      conversion_rates    = offer_list.collect(&:conversion_rate)
      prices              = offer_list.collect(&:price)
      avg_revenues        = offer_list.collect(&:avg_revenue)
      bids                = offer_list.collect(&:bid_for_ranks)
      cvr_mean            = conversion_rates.mean
      cvr_std_dev         = conversion_rates.standard_deviation
      price_mean          = prices.mean
      price_std_dev       = prices.standard_deviation
      avg_revenue_mean    = avg_revenues.mean
      avg_revenue_std_dev = avg_revenues.standard_deviation
      bid_mean            = bids.mean
      bid_std_dev         = bids.standard_deviation

      stats = { :cvr_mean => cvr_mean, :cvr_std_dev => cvr_std_dev, :price_mean => price_mean, :price_std_dev => price_std_dev,
        :avg_revenue_mean => avg_revenue_mean, :avg_revenue_std_dev => avg_revenue_std_dev, :bid_mean => bid_mean, :bid_std_dev => bid_std_dev }

      bucket = S3.bucket(BucketNames::OFFER_DATA)
      bucket.objects["offer_rank_statistics"].write(:data => Marshal.dump(stats))
      Mc.put("s3.offer_rank_statistics", stats)
    end

    def get_offer_stats
      Mc.get_and_put("s3.offer_rank_statistics") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.objects["offer_rank_statistics"].read)
      end
    end

    def cache_reengagement_offers
      ReengagementOffer.visible.select('app_id').group('app_id').each do |reengagement_offer|
        ReengagementOffer.cache_by_app_id(reengagement_offer.app_id)
      end
    end

    def cache_papaya_offers
      papaya_offers = {}
      Offer.enabled_offers.papaya_app_offers.each do |o|
        papaya_offers[o.id] = o.papaya_user_count
      end
      Offer.enabled_offers.papaya_action_offers.each do |o|
        papaya_offers[o.id] = o.papaya_user_count
      end
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      bucket.objects["papaya_offers"].write(:data => Marshal.dump(papaya_offers))
      Mc.put("s3.papaya_offers", papaya_offers)
    end

    def get_papaya_offers
      Mc.get_and_put("s3.papaya_offers") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.objects["papaya_offers"].read)
      end
    end

  end
end
