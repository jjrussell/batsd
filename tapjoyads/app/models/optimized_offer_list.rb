class OptimizedOfferList

  ORDERED_KEY_ELEMENTS = %w(algo_id is_tjm platform country currency_id device_type).map(&:to_sym)
  S3_FOLDERS = %w(tjm generic)

  class << self

    def get_offer_list(starting_key)
      keys = relaxed_constraints_keys(starting_key)
      offers = nil
      while offers.nil? && !keys.empty?
        offers = Mc.get("s3.optimized_offer_list.#{keys.pop}")
      end
      offers
    end

    def cache_all
      S3_FOLDERS.each do |s3_folder|
        all_s3_keys_in_folder(s3_folder).each do |key|
          cache_offer_list(key)
        end
      end
    end

    def cache_offer_list(key)
      offers = s3_offer_list(key).sort_by{ |offer| -offer['rank_score'] }
      offers.each{ |offer_hash| offer_hash['offer'] = Offer.find(offer_hash['offer_id']) }
      Mc.put("s3.optimized_offer_list.#{key}", offers) rescue puts "saving to Memcache failed"
      S3.bucket(BucketNames::OPTIMIZATION_CACHE).objects[key].write(:data => offers) rescue puts "saving to S3 failed"
    end

    private

    #key default hierarchy stuff

    def relaxed_constraints_keys(starting_key)
      key_hash = hash_for_key(starting_key)
      [ { }, { :country => nil }, { :currency_id => nil }, { :country => nil, :currency_id => nil }
      ].map{ |params| key_for_hash(key_hash, params) }.uniq
    end

    def hash_for_key(key, overrides={})
      Hash[ ORDERED_KEY_ELEMENTS.zip(key.split('.').map{ |x| x == "" ? nil : x }) ].merge(overrides)
    end

    def key_for_hash(key_hash, overrides={})
      ORDERED_KEY_ELEMENTS.map{ |x| key_hash.merge(overrides)[x] }.join('.')
    end

    #S3 stuff

    def all_s3_keys_in_folder(s3_folder)
      s3_bucket(s3_folder).objects.map &:key
    end

    def s3_offer_list(id)
      json = s3_bucket(folder_for_id(id)).objects[id].read
      items = JSON.parse(json)
      return nil if items['enabled'] == 'false'
      items['offers']
    end

    def s3_bucket(folder=nil)
      bucket_name = BucketNames::OPTIMIZATION
      bucket_name += "/#{folder}" if folder.present?
      S3.bucket(bucket_name)
    end
  end
end
