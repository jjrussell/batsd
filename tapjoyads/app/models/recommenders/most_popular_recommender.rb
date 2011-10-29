class Recommenders::MostPopularRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'

  def initialize
    @most_popular_apps = {}  #the most popular apps
    parse_file self.class::MOST_POPULAR_FILE
  end

  def most_popular_apps(opts={})
    top_apps_in_hash(@most_popular_apps, opts[:n])
  end

  def recommendations_for_app(app, opts={})
    most_popular_apps(opts)
  end

  def recommendations_for_udid(udid, opts={})
    most_popular_apps(opts)
  end

  def random_app
    @most_popular_apps.keys.sample
  end

  private
  def parse_line(line, file_name)
    parse_popular_line(line)
  end

  def parse_popular_line(line)
    app_id, name, count = line.split("\t")
    @most_popular_apps[app_id] = count.to_i
  end
end
