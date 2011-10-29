class Recommenders::JoeyBayesianRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'
  APP_FILE          = 'app_app_matrix.txt'
  DEVICE_FILE       = 'udid_reco.txt'

  def initialize
    @recs_for_app = {} #recommendations for a particular application
    @recs_for_udid = {} #recommendations for a particular user
    @most_popular_apps = {}  #the most popular apps
    parse_file self.class::APP_FILE
    parse_file self.class::DEVICE_FILE
    parse_file self.class::MOST_POPULAR_FILE
  end

  def most_popular_apps(opts={})
    top_apps_in_hash(@most_popular_apps, opts[:n])
  end

  def recommendations_for_app(app, opts={})
    top_apps_in_hash(@recs_for_app[app], opts[:n])
  end

  def recommendations_for_udid(udid, opts={})
    top_apps_in_hash(@recs_for_udid[udid], opts[:n])
  end

  def random_udid
    @recs_for_udid.keys.sample
  end

  def random_app
    @recs_for_app.keys.sample
  end

  private
  def parse_line(line, file_name)
    case file_name
    when self.class::MOST_POPULAR_FILE then parse_popular_line(line)
    when self.class::APP_FILE then parse_app_app_line(line)
    when self.class::DEVICE_FILE then parse_udid_line(line)
    else raise "Wrong File Name!"
    end
  end

  def parse_popular_line(line)
    app_id, name, count = line.split("\t")
    @most_popular_apps[app_id] = count.to_i
  end

  def parse_udid_line(line)
    udid, recommendations = line.split(',', 2)
    @recs_for_udid[udid] = parse_recommendations(recommendations.gsub(/"/, ''))
  end

  def parse_app_app_line(line)
    target, recommendations = line.split(';', 2)
    @recs_for_app[target] = parse_recommendations(recommendations)
  end

  def parse_recommendations(recommendations)
    Hash[recommendations.split(';').map { |x| x.split(',') }.map { |x| x.length == 1 ? x + ["0"] : x }.map { |app, percent| [app, percent.to_f] }]
  end
end
