class RecommendationList
  Offer # This class caches Offers, so the Offer model must be loaded

  attr_reader :offers

  MINIMUM           = 7
  MOST_POPULAR_FILE = 'most_popular.txt'
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'daily/udid_apps_reco.dat'

  def initialize(options = {})
    @device      = options[:device]
    @device_type = options[:device_type]
    @geoip_data  = options[:geoip_data] || {}
    @os_version  = options[:os_version]

    @offers = RecommendationList.for_device(@device.id).reject { |offer| recommendation_reject?(offer) }
    @offers |= RecommendationList.for_app(@device.last_app_run).reject { |offer| recommendation_reject?(offer) } if @offers.length < MINIMUM
    @offers |= RecommendationList.most_popular.reject { |offer| recommendation_reject?(offer) } if @offers.length < MINIMUM
  end

  def apps
    @offers[0...MINIMUM].collect { |o| CachedApp.new(o) }
  end

  class << self

    def cache_all
      cache_most_popular
      cache_raw_by_app
      cache_raw_by_device
    end

    def cache_most_popular
      offers = []
      parse_recommendations_file(MOST_POPULAR_FILE) do |rec|
        begin
          offers << Offer.find_in_cache(rec.split("\t").first)
        rescue ActiveRecord::RecordNotFound => e
          next
        end
      end
      offers.compact!
      
      Mc.distributed_put('s3.recommendations.offers.most_popular', offers)
    end

    def cache_raw_by_app
      parse_recommendations_file(APP_FILE) do |recs|
        recs = recs.split(/[;,]/, 2)
        app_id = recs.first
        recommendations = recs.second
        Mc.put("s3.recommendations.raw.by_app.#{app_id}", recommendations)
      end
    end

    def cache_raw_by_device
      parse_recommendations_file(DEVICE_FILE) do |recs|
        recs = recs.split(/[;,]/, 2)
        device_id = recs.first
        recommendations = recs.second
        Mc.put("s3.recommendations.raw.by_device.#{device_id}", recommendations)
      end
    end

    def raw_for_app(app_id)
      Mc.get("s3.recommendations.raw.by_app.#{app_id}") || ""
    end

    def raw_for_device(device_id)
      Mc.get("s3.recommendations.raw.by_device.#{device_id}") || ""
    end

    def most_popular
      Mc.distributed_get('s3.recommendations.offers.most_popular') || []
    end

    def for_app(app_id)
      Mc.get_and_put("s3.recommendations.offers.by_app.#{app_id}", false, 1.day) do
        offers = []
        raw_for_app(app_id).split(';').each do |recommendation|
          begin  
            offers << Offer.find_in_cache(recommendation.split(',').first)
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        offers.compact!

        offers.any? ? offers : nil
      end
    end

    def for_device(device_id)
      Mc.get_and_put("s3.recommendations.offers.by_device.#{device_id}", false, 1.day) do
        offers = []
        raw_for_device(device_id).split(';').each do |recommendation|
          begin  
            offers << Offer.find_in_cache(recommendation.split(',').first)
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        offers.compact!
        
        offers.any? ? offers : nil
      end
    end

    def parse_recommendations_file(file_name, &blk)
      S3.bucket(BucketNames::TAPJOY_GAMES).objects[file_name].read.each do |row|
        yield(row.chomp)
      end
    end

  end

  private

  def recommendation_reject?(offer)
    offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version)
  end

end
