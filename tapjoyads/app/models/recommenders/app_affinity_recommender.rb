class Recommenders::AppAffinityRecommender < Recommender
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'daily/udid_apps_reco.dat'

  def cache_all
    cache_most_popular
    cache_by_app
    cache_by_device
  end

  def most_popular(opts = {})
    Recommender.instance(:most_popular_recommender).most_popular(opts)
  end

  def for_app(app_id, opts = {})
    out = Mc.get("s3.recommendations.raw_list.by_app.#{app_id}") || []
    first_n(out, opts[:n])
  end

  def for_device(device_id, opts = {})
    out = Mc.get("s3.recommendations.raw_list.by_device.#{device_id}") || []
    first_n(out, opts[:n])
  end

  def cache_most_popular
    Recommender.instance(:most_popular_recommender).cache_all if most_popular.empty?
  end

  def cache_by_app
    parse_recommendations_file(APP_FILE) do |recs|
      # each line for the file for app recommendations has the format app;recommendations
      # where recommendations has the form app,weight;app,weight;...;app,weight
      app_id, recommendations = recs.split(/[;,]/, 2)
      Mc.put("s3.recommendations.raw_list.by_app.#{app_id}", parse_recommendations(recommendations))
    end
  end

  def cache_by_device
    parse_recommendations_file(DEVICE_FILE) do |recs|
      # each line for the file for app recommendations has the format app;recommendations
      # where recommendations has the form app,weight;app,weight;...;app,weight
      device_id, recommendations = recs.split(/[;,]/, 2)
      Mc.put("s3.recommendations.raw_list.by_device.#{device_id}", parse_recommendations(recommendations))
    end
  end

  private
  def parse_recommendations(recommendations)
    # recommendations have the form app,weight;app,weight;...;app,weight, there are some bad records that don't have a weight
    # so we are setting those to 0, basically to no recommendation for that app
    recommendations.split(';').map { |x| x.split(',') }.map { |x| x.length == 1 ? x + ["0"] : x }.map { |app, weight| [app, weight.to_f] }.sort_by { |app, weight| -weight }
  end
end
