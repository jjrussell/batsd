class OptimizedOfferList

  ORDERED_ID_KEYS = %w(algo_id is_tjm platform country currency_id device_type).map(&:to_sym)
  FOLDERS = %w(tjm generic)

  class << self

    def offer_list(key)
      offers = Mc.get("s3.optimized_offer_list.#{key}")
      ids = relaxed_ids(key) if offers.nil?
      while offers.nil?
        offers = Mc.get("s3.optimized_offer_list.#{key}")
      end
      offers
    end


    def cache_all
      FOLDERS.each{ |s3_folder| cache_all_in_folder(folder) }
    end

    def cache_all_in_folder(s3_folder)
      all_s3_keys_in_folder(s3_folder).each do |key|
        cache_list(key)
      end
    end

    def cache_list(key)
      offers = s3_offer_list(key).sort_by{ |offer| -offer['rank_score'] }
      offers.each{ |offer_hash| offer_hash[:offer] = Offer.find(offer_hash['offer_id']) }
      #cache in memcache
      Mc.put("s3.optimized_offer_list.#{key}", offers) rescue puts "saving to Memcache failed"
      #save in s3 as well
      S3.bucket(BucketNames::OPTIMIZATION_CACHE).objects[key].write(:data => offers)
    end


    def s3_offer_list(id)
      json = s3_bucket(folder_for_id(id)).objects[id].read
      list = JSON.parse(json)
      return nil if list['enabled'] == 'false' #TODO check if it returns 'false' string or false boolean
      list['offers']
    end


    private

    def hash_for_id(id, overrides={})
      Hash[ ID_KEYS.zip(id.split('.').map{|x| x == "" ? nil : x}) ].merge(overrides)
    end

    def id_for_hash(id_hash, overrides={})
      ID_KEYS.map{ |x| id_hash.merge(overrides)[x] }.join('.')
    end

    def folder_for_id(id)
      hash_for_id(id)[:is_tjm].to_i == 1 ? 'tjm' : 'generic'
    end

    def relaxed_ids(id)
      relaxed_constraints_ids_for_hash(hash_for_id(id))
    end

    def relaxed_constraints_ids_for_hash(id_hash)
      [id_for_hash(id_hash), id_for_hash(id_hash, :country => nil),
        id_for_hash(id_hash, :currency_id => nil), id_for_hash(id_hash, :country => nil, :currency_id => nil)
      ].uniq - [id_hash]
    end

    def option_for_id(id)
      exists = s3_file_exists?(id)
      return id if exists
      options = id_options_for_hash(hash_for_id(id))
      until(options.empty?)
        id = options.pop
        exists = s3_file_exists?(id)
        return id if exists
      end
      return nil
    end

    def all_s3_keys_in_folder(s3_folder)
      s3_bucket(s3_folder).objects.map &:key
    end

    def s3_file_exists?(id)
      s3_bucket(folder_for_id(id)).objects[id].exists?
    end

    def s3_bucket(folder=nil)
      bucket_name = BucketNames::OPTIMIZATION
      bucket_name += "/#{folder}" if folder.present?
      S3.bucket(bucket_name)
    end

  end
end
