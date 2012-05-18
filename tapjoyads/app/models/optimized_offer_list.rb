class OptimizedOfferList

  ORDERED_KEY_ELEMENTS = %w(algorithm source platform country currency_id device_type).map(&:to_sym)

  class << self

    def get_offer_list(options)
      offers = Mc.distributed_get(cache_key_for_options(options))
      offers = Mc.distributed_get(cache_key_for_options(options.merge({ :country => nil }))) if offers.nil?
      offers = Mc.distributed_get(cache_key_for_options(options.merge({ :currency_id => nil }))) if offers.nil?
      offers = Mc.distributed_get(cache_key_for_options(options.merge({ :currency_id => nil, :country => nil }))) if offers.nil?

      offers || []
    end

    def cache_all
      s3_optimization_keys.each do |key|
        cache_offer_list(key)
      end
    end

    def cache_offer_list(key)
      cache_key = cache_key_for_options(options_for_s3_key(key))
      offers_json = s3_json_offer_data(key)
      Mc.distributed_delete(cache_key) and return if offers_json['enabled'] == 'false'

      offers = offers_json['offers']
      offers.collect do |offer_hash|
        Offer.find(offer_hash['offer_id'], :select => Offer::OFFER_LIST_REQUIRED_COLUMNS).tap do |offer|
          offer.rank_score = offer_hash['rank_score']
        end.for_caching
      end

      Mc.distributed_put(cache_key, offers) rescue puts "saving to Memcache failed"
      # s3_cached_optimization_bucket.objects[cache_key].write(:data => Marshal.dump(offers)) rescue puts "saving to S3 failed"
    end

    private

    def cache_key_for_options(options)
      options = options.clone
      # TODO: dry up this sort of thing. We do it in a million spots.
      algorithm   = options.delete(:algorithm)   { nil }
      source      = options.delete(:source)      { |k| raise "#{k} is a required argument" }
      platform    = options.delete(:platform)    { |k| raise "#{k} is a required argument" }
      country     = options.delete(:country)     { nil }
      currency_id = options.delete(:currency_id) { nil }
      device_type = options.delete(:device_type) { |k| raise "#{k} is a required argument" }
      raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

      "s3.optimized_offer_list.#{algorithm}.#{source}.#{platform}.#{country}.#{currency_id}.#{device_type}"
    end

    def options_for_s3_key(key)
      key_without_directory = key.split("/").last
      split_key = key_without_directory.split(".")
      source = case split_key[1]
      when '0'
        'offerwall'
      when '1'
        'tj_games'
      end

      { :algorithm => split_key[0], :source => source, :platform => split_key[2],
        :country => split_key[3], :currency_id => split_key[4], :device_type => split_key[5], }
    end

    #S3 stuff

    def s3_optimization_keys
      @s3_optimization_keys ||= s3_optimization_bucket.objects.map(&:key).reject { |keys| keys.last == "/" }
    end

    def s3_json_offer_data(id)
      json = s3_optimization_bucket.objects[id].read
      JSON.parse(json)
    end

    def s3_optimization_bucket
      @s3_optimization_bucket ||= S3.bucket(BucketNames::OPTIMIZATION)
    end

    def s3_cached_optimization_bucket
      @s3_cached_optimization_bucket ||= S3.bucket(BucketNames::OPTIMIZATION_CACHE)
    end
  end
end
