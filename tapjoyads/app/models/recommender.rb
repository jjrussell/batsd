class Recommender  #interface for all recommenders
  ACTIVE_RECOMMENDERS = { #when recommender is ready, put name here
    :joey_bayesian_recommender => "Joey's Bayesian Recommender",
    :most_popular_recommender => "Popular Apps Recommender"
  } 

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
  
  
  class << self
    def type
      self.name.split("::").last.snake_case.to_sym
    end
    def instance #avoid creating a recommender every time
      @@recommenders ||= {}
      @@recommenders[self.type] ||= self.new
    end    
  end
  
  def type
    self.class.type
  end
  
  def inspect
    "#{self.type}: #{self.object_id}"
  end
  
  def to_s
    self.inspect
  end
  
end