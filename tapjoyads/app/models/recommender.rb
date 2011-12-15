class Recommender  #Interface for all recommenders.
  DEFAULT_RECOMMENDER = :app_affinity_recommender
  ACTIVE_RECOMMENDERS = { #When a new recommender is ready, put name here.
    :app_affinity_recommender => "App Affinity Recommender",
    :most_popular_recommender => "Popular Apps Recommender"
  }

  class << self
    def type
      self.name.split("::").last.snake_case.to_sym
    end

    def instance(recommender_type = DEFAULT_RECOMMENDER)
      @@recommenders ||= {}
      if is_active?(recommender_type)
        @@recommenders[recommender_type.to_sym] ||= "Recommenders::#{recommender_type.to_s.camelize}".constantize.new
      elsif is_active?(self.type)
        @@recommenders[self.type] ||= self.new
      else
        raise "Wrong recommender type, Recommenders::#{(recommender_type || self.type).to_s.camelize} does not exist"
      end
    end

    def is_active?(recommender_type)
      return false if recommender_type.nil?
      ACTIVE_RECOMMENDERS.keys.member?(recommender_type.to_sym)
    end
  end

  # RECOMMENDER INTERFACE
  def cache_all
    raise "Child class must implement cache_all"
  end

  def most_popular(opts={})
    raise "Child class must implement most_popular(opts={})"
  end

  def for_app(app, opts={})
    raise "Child class must implement for_app(app, opts={})"
  end

  def for_device(device, opts={})
    raise "Child class must implement for_device(device, opts={})"
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
    offer = Offer.find(app_id) rescue nil
    offer.nil? ? nil : offer.name
  end

  def first_n(list, n)
     n = 20 unless n && n.is_a?(Numeric)
     list[0...n]
   end

  def parse_recommendations_file(file_name, &blk)
    S3.bucket(BucketNames::TAPJOY_GAMES).objects[file_name].read.each do |row|
      yield(row.chomp)
    end
  end
end
