class OptimizedOfferList

  ORDERED_KEY_ELEMENTS = %w(algorithm source platform country currency_id device_type).map(&:to_sym)
  GROUP_SIZE = 200

  class << self

    def get_offer_list(options)
      offers = get_cached_offer_list(options)
      offers = get_cached_offer_list(options.merge({ :country => nil })) if offers.blank?
      offers = get_cached_offer_list(options.merge({ :currency_id => nil })) if offers.blank?
      offers = get_cached_offer_list(options.merge({ :currency_id => nil, :country => nil })) if offers.blank?

      offers || []
    end

    def cache_all
      s3_optimization_keys.each do |key|
        begin
          Sqs.send_message(QueueNames::CACHE_OPTIMIZED_OFFER_LIST, key)
        rescue
          puts "failed to insert CACHE_OPTIMIZED_OFFER_LIST job for #{key} into queue"
        end
      end
    end

    def get_cached_offer_list(options = {})
      cache_key = cache_key_for_options(options)
      group = 0
      offers = []

      loop do
        offer_group = Mc.distributed_get("#{cache_key}.#{group}")
        break if offer_group.nil?
        offers |= offer_group
        break unless offer_group.length == GROUP_SIZE
        group += 1
      end

      offers
    end

    def delete_cached_offer_list(cache_key)
      group = 0
      until (offer_group = Mc.distributed_get("#{cache_key}.#{group}")).nil?
        Mc.distributed_delete("#{cache_key}.#{group}")
        group += 1
      end
    end

    def cache_offer_list(key)
      # TODO: New relic alerts?
      options = options_for_s3_key(key)
      cache_key = cache_key_for_options(options)
      offers_json, last_modified_at = s3_json_offer_data(key)
      if offers_json['enabled'] == 'false'
        delete_cached_offer_list(cache_key)
        return
      end

      offers = get_offers_for_cache(offers_json['offers'], options[:device_type], options[:platform])
      offers = offers.sort_by {|offer| -offer.rank_score.to_f }
      current_time = Time.now
      cached_offer_list = CachedOfferList.new
      post_processed_offer_with_rank = []

      offers.each_with_index do |offer, i|
        offer.cached_offer_list_id = cached_offer_list.id
        offer.cached_offer_list_type = 'optimized'
        post_processed_offer_with_rank << {'offer_id' => offer.id, 'rank' => (i + 1)}
      end

      group = 0
      begin
        offers.each_slice(GROUP_SIZE) do |offer_group|
          Mc.distributed_put("#{cache_key}.#{group}", offer_group, false, 1.day)
          group += 1
        end
      rescue
        Rails.logger.warn "saving #{cache_key} to Memcache failed"
      end

      # TODO: Cache stuff into S3

      cached_offer_list.generated_at = last_modified_at
      cached_offer_list.cached_at = current_time
      cached_offer_list.memcached_key = cache_key
      cached_offer_list.offer_list = post_processed_offer_with_rank
      cached_offer_list.cached_offer_type = 'optimized'
      cached_offer_list.source = key
      cached_offer_list.save
      WebRequest.log_cached_offer_list(cached_offer_list)

      Mc.distributed_put("#{cache_key}.#{group}", [], false, 1.day)
    end

    def disable_all
      s3_optimization_keys.each do |key|
        cache_key = cache_key_for_options(options_for_s3_key(key))
        Mc.distributed_delete(cache_key)
      end
    end

    private

    def get_offers_for_cache(offers_json, device_type, platform)
      offers_json.collect do |offer_hash|
        begin
          current_offer = Offer.find(offer_hash['offer_id'])
          next if current_offer.disabled?
          next if current_offer.device_platform_mismatch?(device_type)
          next if current_offer.app_platform_mismatch?(platform)
          Offer.find(offer_hash['offer_id'], :select => Offer::OFFER_LIST_REQUIRED_COLUMNS).optimization_override(offer_hash, false).for_caching
        rescue
          Rails.logger.warn "Error with #{offer_hash.inspect}" and next
        end
      end.compact
    end

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

      "s3.optimized_offer_list.#{algorithm}.#{source}.#{platform}.#{country}.#{currency_id}.#{device_type}.#{Offer.acts_as_cacheable_version}"
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

    def s3_key_for_options(options)
      options[:source] = case options[:source]
      when 'offerwall' then 0
      when 'tj_games' then 1
      else options[:source]
      end
      ORDERED_KEY_ELEMENTS.map{ |k| options[k] }.join('.')
    end

    #S3 stuff

    def s3_optimization_keys
      @s3_optimization_keys ||= s3_optimization_bucket.objects.map(&:key).reject { |keys| keys.last == "/" }
    end

    def s3_json_offer_data(id)
      s3_object = s3_optimization_bucket.objects[id]
      json = s3_object.read
      [JSON.parse(json), s3_object.last_modified]
    end

    def s3_optimization_bucket
      @s3_optimization_bucket ||= S3.bucket(BucketNames::OPTIMIZATION)
    end

    def s3_cached_optimization_bucket
      @s3_cached_optimization_bucket ||= S3.bucket(BucketNames::OPTIMIZATION_CACHE)
    end
  end
end
