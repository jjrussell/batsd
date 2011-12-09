class Recommenders::AppAffinityRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'daily/udid_apps_reco.dat'

  def cache_all
    cache_most_popular
    cache_by_app
    cache_by_device
  end

  def most_popular(opts = {})
    out = Mc.distributed_get('s3.recommendations.raw_list.most_popular') || []
    first_n out, opts[:n]
  end

  def for_app(app_id, opts = {})
    out = Mc.get("s3.recommendations.raw_list.by_app.#{app_id}") || []
    first_n out, opts[:n]
  end

  def for_device(device_id, opts = {})
    out = Mc.get("s3.recommendations.raw_list.by_device.#{device_id}") || []
    first_n out, opts[:n]
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

  def cache_by_app
    parse_recommendations_file(APP_FILE) do |recs|
      app_id, recommendations = recs.split(/[;,]/, 2)
      Mc.put("s3.recommendations.raw_list.by_app.#{app_id}", parse_recommendations(recommendations))
    end
  end

  def cache_by_device
    parse_recommendations_file(DEVICE_FILE) do |recs|
      device_id, recommendations = recs.split(/[;,]/, 2)
      Mc.put("s3.recommendations.raw_list.by_device.#{device_id}", parse_recommendations(recommendations))
    end
  end

  private
  def first_n(list, n)
    n = 20 unless n && n.is_a?(Numeric)
    list[0...n]
  end

  def parse_recommendations(recommendations)
    recommendations.split(';').map { |x| x.split(',') }.map { |x| x.length == 1 ? x + ["0"] : x }.map { |app, weight| [app, weight.to_f] }.sort_by { |app, weight| -weight }
  end

  def parse_recommendations_file(file_name, &blk)
    S3.bucket(BucketNames::TAPJOY_GAMES).objects[file_name].read.each do |row|
      yield(row.chomp)
    end
  end
end
