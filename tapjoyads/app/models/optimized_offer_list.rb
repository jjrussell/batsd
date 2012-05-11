class OptimizedOfferList

  ORDERED_ID_KEYS = %w(algo_id is_tjm platform country currency_id device_type).map(&:to_sym)
  FOLDERS = %w(tjm generic)

  class << self

    def cache_all
      FOLDERS.each{ |s3_folder| cache_folder(folder) }
    end

    def cache_folder(s3_folder)
      all_s3_keys_in_folder(s3_folder).each do |key|
        cache_key(key)
      end
    end

    def cache_key(key)
      s3_offer_list(key).each{ |offer_hash| offer_hash[:offer] = Offer.find(offer_hash['offer_id']) }
      #TODO fix this, stole it directly from recommendation list
      Mc.get_and_put("s3.optimized_offer_list.#{key}.#{Offer.acts_as_cacheable_version}", false, 1.hour) do
        offers = []
        Recommender.instance.for_app(app_id).each do |recommendation_hash|
          recommendation_hash[:offer] = Offer.find_in_cache(recommendation_hash[:recommendation])
          next if recommendation_hash[:offer].nil?
          offers << recommendation_hash
        end
        offers.any? ? offers : nil
      end || []
      # ALSO TODO write to amazon here
    end


    def s3_offer_list(id)
      json = s3_bucket(folder_for_id(id)).objects[id].read
      JSON.parse(json)['offers']
    end

    def instance(list)
      # try to get the current cached list, if not present, try to get the previous
      # todo, make it go through a graceful decay of current => previous and also specific => general
    end

    def cache(list) #also try to do this asynchronously
      # get the list from s3
      # if list found, parse json, and find offers for each of the ids
      # cache the found list by "list.id:rounded_timestamp_to_half_hour"
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


    def parse_recommendations_file(file_name, zipped=false, &blk)
      file = S3.bucket("BucketNames::OPTIMIZATION").objects[file_name].read #todo put it in bucketlists
      file = Zlib::GzipReader.new(StringIO.new(file)) if zipped
      file.each_line do |row|
        yield(row.chomp)
      end
    end

  end


end
