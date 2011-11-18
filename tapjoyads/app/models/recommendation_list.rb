class RecommendationList
  Offer

  attr_reader :offers

  MINIMUM           = 7
  MOST_POPULAR_FILE = 'most_popular.txt'
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'udid_reco.txt'

  def initialize(options = {})
    @device       = options[:device]
    @device_type  = options[:device_type]
    @geoip_data   = options[:geoip_data] || {}
    @os_version   = options[:os_version]

    @offers = RecommendationList.for_device(@device.id).reject { |offer| offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version) }
    @offers |= RecommendationList.for_app(@device.last_app_run).reject { |offer| offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version) } if @offers.length < MINIMUM
    @offers |= RecommendationList.most_popular.reject { |offer| offer.recommendation_reject?(@device, @device_type, @geoip_data, @os_version) } if @offers.length < MINIMUM
  end

  def apps
    @offers[0...MINIMUM].collect { |o| CachedApp.new(o) }
  end

  class << self

    def cache_all
      cache_most_popular
      cache_by_apps
      # cache_by_devices
    end

    def cache_most_popular
      recommendations = []
      parse_recommendations_file('most_popular.txt') do |rec|
        begin
          recommendations << Offer.find_in_cache(rec.split("\t").first)
        rescue ActiveRecord::RecordNotFound => e
          next
        end
      end
      Mc.distributed_put('s3.recommendations.most_popular', recommendations)
    end

    def cache_by_apps
      parse_recommendations_file('app_app_matrix.txt') do |recs|
        recommendations = []
        recs = recs.split(/[;,]/, 2)
        app_id = recs.shift
        recs.first.split(/;/).each do |rec|
          begin
            recommendations << Offer.find_in_cache(rec.split(',').first.gsub(/"/, ""))
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        Mc.put("s3.recommendations.by_app.#{app_id}", recommendations)
      end
    end

    def cache_by_devices
      parse_recommendations_file('udid_reco.txt') do |recs|
        recommendations = []
        recs = recs.split(/[;,]/, 2)
        device_id = recs.shift
        recs.first.split(';').each do |rec|
          begin
            recommendations << Offer.find_in_cache(rec.split(',').first.gsub(/"/, ""))
          rescue ActiveRecord::RecordNotFound => e
            next
          end
        end
        Mc.put("s3.recommendations.by_device.#{device_id}", recommendations)
      end
    end

    def most_popular
      Mc.distributed_get('s3.recommendations.most_popular') || []
    end

    def for_app(app_id)
      Mc.distributed_get("s3.recommendations.by_app.#{app_id}") || []
    end

    def for_device(device_id)
      Mc.get("s3.recommendations.by_device.#{device_id}") || []
    end

    def parse_recommendations_file(file_name, &blk)
      S3.bucket(BucketNames::TAPJOY_GAMES).objects[file_name].read.split(/[\r\n]/).each do |row|
        yield(row)
      end
    end

  end

end
