class Recommenders::MostPopularRecommender < Recommender
  MOST_POPULAR_FILE = 'most_popular.txt'

  def initialize
    @most_popular_apps = {}  #the most popular apps
    @app_names = {}    #names of the apps
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
    @app_names.keys.rand
  end
  
  def app_name(app_id)
    @app_names[app_id]
  end

  
  private
  
  def parse_file(file_name)
    file_lines(file_name).each do |line|
      parse_line(line, file_name)
    end
  end
    
  def parse_line(line, file_name)
    case file_name
      when self.class::MOST_POPULAR_FILE then parse_popular_line(line)
      else raise "Wrong File Name!"
    end
  end
  
  def parse_popular_line(line)
    app_id, name, count = line.split("\t")
    @app_names[app_id] = name
    @most_popular_apps[app_id] = count.to_i
  end
  
  def file_lines(file_name)
    @file_lines ||= {}
    # @file_lines[file_name] ||= S3.bucket(BucketNames::TAPJOY_GAMES).get(file_name).split(/[\r\n]/)
    # @file_lines[file_name] ||= S3.bucket("dev_tj-games").get(file_name).split(/[\r\n]/)
    @file_lines[file_name] ||= File.read(File.join('/Users/francisco/code/tapjoy/data', file_name)).split(/[\r\n]/)
  end
    
  
end
  

