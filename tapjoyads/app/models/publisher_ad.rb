class PublisherAd < SimpledbResource
  
  def initialize(key, load = true)
    super 'publisher_ad', key, load
  end
end
