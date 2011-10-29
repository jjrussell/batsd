class Recommender  #Interface for all recommenders.
  ACTIVE_RECOMMENDERS = { #When a new recommender is ready, put name here.
    :joey_bayesian_recommender => "Joey's Bayesian Recommender",
    :most_popular_recommender => "Popular Apps Recommender"
  }

  class << self
    def type
      self.name.split("::").last.snake_case.to_sym
    end

    def instance
      @@recommenders ||= {}
      @@recommenders[self.type] ||= self.new
    end
  end

  # RECOMMENDER INTERFACE
  def most_popular_apps(opts={})
    raise "Child class must implement most_popular_apps(opts={})"
  end

  def recommendations_for_app(app, opts={})
    raise "Child class must implement recommendations_for_app(app, opts={})"
  end

  def recommendations_for_udid(udid, opts={})
    raise "Child class must implement recommendations_for_udid(udid, opts={})"
  end
  # END RECOMMENDER INTERFACE

  def type
    self.class.type
  end

  def inspect
    "#{self.type}: #{self.object_id}"
  end

  def to_s
    self.inspect
  end

  def app_name(app_id)
    app = App.find_by_id app_id
    app.nil? ? nil : app.name
  end

  protected
  def parse_file(file_name)
    file_lines(file_name).each { |line| parse_line(line, file_name) }
  end

  def file_lines(file_name)
    @file_lines ||= {}
    @file_lines[file_name] ||= S3.bucket(BucketNames::TAPJOY_GAMES).objects[file_name].read.split(/[\r\n]/)
  end

  def top_apps_in_hash(weighted_apps_hash, n)
    return [] if weighted_apps_hash.nil?
    n = 10 if n.nil? || !n.is_a?(Numeric)
    weighted_apps_hash.sort_by { |app, weight| -weight }[0...n].map { |x, y| { :app_name => app_name(x), :app_id => x, :weight => y } }
  end
end
