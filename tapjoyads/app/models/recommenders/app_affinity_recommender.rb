class Recommenders::AppAffinityRecommender < Recommender
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'daily/udid_apps_reco.dat'
  DEVICE_WITH_EXPLANATION_FILE = 'daily/udid_apps_reco_src.gz'

  def cache_all
    cache_most_popular
    cache_by_app
    cache_by_device(true)
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
      next if recommendations.nil?
      Mc.put("s3.recommendations.raw_list.by_app.#{app_id}", parse_recommendations(recommendations).map{ |x| { :explanation => app_id }.merge(x) }) rescue puts "error parsing recommendations for app \n#{recs}"
    end
  end

  def cache_by_device(with_explanation = false)
    file = with_explanation ? DEVICE_WITH_EXPLANATION_FILE : DEVICE_FILE
    parse_recommendations_file(file, with_explanation) do |recs|
      # each line for the file for app recommendations has the format app;recommendations
      # where recommendations has the form app,weight;app,weight;...;app,weight
      device_id, recommendations = recs.split(/[;,]/, 2)
      next if recommendations.nil?
      Mc.put("s3.recommendations.raw_list.by_device.#{device_id}", parse_recommendations(recommendations, with_explanation)) rescue puts "error parsing recommendations for device \n#{recs}"
    end
  end

  private
  def parse_recommendations(recommendations, with_explanation = false)
    # recommendations have the form app,weight;...;app,weight, or app,weight,explanation;...;app,weight,explanation;
    #there are some bad records that don't have a weight, so we are selecting only records with the correct length
    rec_tuples = recommendations.split(';').map{ |x| x.split(',') }
    if with_explanation
      recs = rec_tuples.select{ |x| x.length == 3 }.map{ |rec, weight, exp| { :recommendation => rec, :weight => weight.to_f, :explanation => exp } }
    else
      recs = rec_tuples.select{ |x| x.length == 2 }.map{ |rec, weight| { :recommendation => rec, :weight => weight.to_f } }
    end
    recs.sort_by{ |rec| -rec[:weight] }
  end
end
