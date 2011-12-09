class Recommenders::MostPopularRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'

  def cache_all
    cache_most_popular
  end

  def most_popular(opts = {})
    Recommender.instance(:app_affinity_recommender).most_popular(opts)
  end

  def for_app(app_id, opts = {})
    most_popular(opts)
  end

  def for_device(device_id, opts = {})
    most_popular(opts)
  end

  def cache_most_popular
    Recommender.instance(:app_affinity_recommender).cache_most_popular if most_popular == []
  end
end
