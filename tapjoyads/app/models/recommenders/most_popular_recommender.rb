class Recommenders::MostPopularRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'

  def cache_all
    cache_most_popular
  end

  def most_popular(opts = {})
    out = Mc.distributed_get('s3.recommendations.raw_list.most_popular') || []
    first_n(out, opts[:n])
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
      rec, name, weight = rec.split("\t")
      list << {:recommendation => rec, :weight => weight.to_f, :explanation => "Popular App"}  unless rec.nil? || weight.nil?
    end
    Mc.distributed_put('s3.recommendations.raw_list.most_popular', list.sort_by{ |rec| -rec[:weight] })
  end

end
