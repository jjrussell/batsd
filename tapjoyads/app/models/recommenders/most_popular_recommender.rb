class Recommenders::MostPopularRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'

  def cache_all
    cache_most_popular
  end

  def most_popular(opts = {})
    out = Mc.distributed_get('s3.recommendations.raw_list.most_popular') || []
    cache_all if out == [] #hack to force caching the first time we use it, remove later
    first_n out, opts[:n]
  end

  def for_app(app_id, opts = {})
    most_popular(opts)
  end

  def for_device(device_id, opts = {})
    most_popular(opts)
  end

  def cache_most_popular
    list = []
    parse_recommendations_file(MOST_POPULAR_FILE) do |rec|
      app_id, name, weight = rec.split("\t")
      weight = weight.nil? ? 0 : weight.to_i
      list << [app_id, weight] unless app_id.nil?
    end
    Mc.distributed_put('s3.recommendations.raw_list.most_popular', list.sort_by{ |app, weight| -weight })
  end

end
