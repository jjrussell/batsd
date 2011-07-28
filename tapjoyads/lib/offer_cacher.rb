class OfferCacher
  
  GROUP_SIZE = 200
  
  class << self
  
    def cache_offers(save_to_s3 = false)
      Benchmark.realtime do
        offer_list = Offer.enabled_offers.nonfeatured.rewarded.for_offer_list.to_a
        cache_unsorted_offers_prerejected(offer_list, Offer::DEFAULT_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.featured.rewarded.for_offer_list + Offer.enabled_offers.nonfeatured.free_apps.rewarded.for_offer_list
        cache_unsorted_offers_prerejected(offer_list, Offer::FEATURED_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.rewarded.for_offer_list.for_display_ads.to_a
        cache_unsorted_offers_prerejected(offer_list, Offer::DISPLAY_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.nonfeatured.non_rewarded.free_apps.for_offer_list.to_a
        cache_unsorted_offers_prerejected(offer_list, Offer::NON_REWARDED_DISPLAY_OFFER_TYPE, save_to_s3)

        offer_list = Offer.enabled_offers.featured.non_rewarded.free_apps.for_offer_list + Offer.enabled_offers.nonfeatured.non_rewarded.free_apps.for_offer_list
        cache_unsorted_offers_prerejected(offer_list, Offer::NON_REWARDED_FEATURED_OFFER_TYPE, save_to_s3)
      end
    end

    def cache_unsorted_offers_prerejected(offers, type, save_to_s3 = false)
      offers.each { |o| o.run_callbacks(:before_cache) }
      App::PLATFORMS.values.each do |platform|
        [ true, false ].each do |hide_rewarded_app_installs|
          cache_offer_list("#{type}.#{platform}.#{hide_rewarded_app_installs}", offers.reject { |o| o.should_reject_from_platform_or_device_type_or_rewarded?(platform, hide_rewarded_app_installs) }, save_to_s3)
        end
      end
    end

    def get_unsorted_offers_prerejected(type, platform, hide_rewarded_app_installs)
      get_offer_list("#{type}.#{platform}.#{hide_rewarded_app_installs}")
    end
    
    def cache_offer_list(key, offers, save_to_s3 = false)
      s3_key = "unsorted_offers.#{key}"
      mc_key = "s3.#{s3_key}.#{SCHEMA_VERSION}"
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      group = 0
    
      offers.compact.each_slice(GROUP_SIZE) do |offer_group|
        bucket.put("#{s3_key}.#{group}", Marshal.dump(offer_group)) if save_to_s3
        Mc.distributed_put("#{mc_key}.#{group}", offer_group, false, 1.day)
        group += 1
      end
    
      bucket.put("#{s3_key}.#{group}", Marshal.dump([])) if save_to_s3
      Mc.distributed_put("#{mc_key}.#{group}", [], false, 1.day)
      group += 1
    
      if save_to_s3
        while bucket.key("#{s3_key}.#{group}").exists?
          bucket.key("#{s3_key}.#{group}").delete
      	  Mc.distributed_delete("#{mc_key}.#{group}")
      	  group += 1
      	end
  	  end
    end

    def get_offer_list(key)
      s3_key = "unsorted_offers.#{key}"
      mc_key = "s3.#{s3_key}.#{SCHEMA_VERSION}"
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      group = 0
      offers = []
    
      loop do
        offer_group = Mc.distributed_get_and_put("#{mc_key}.#{group}", false, 1.day) do
          Marshal.restore(bucket.get("#{s3_key}.#{group}"))
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
      bids                = offer_list.collect(&:bid)
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
      bucket.put("offer_rank_statistics", Marshal.dump(stats))
      Mc.put("s3.offer_rank_statistics", stats)
    end

    def get_offer_stats
      Mc.get_and_put("s3.offer_rank_statistics") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.get("offer_rank_statistics"))
      end
    end
  
  end

end