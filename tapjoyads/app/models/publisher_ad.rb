class PublisherAd < SimpledbResource
  
  def initialize(key, options = {})
    super 'publisher_ad', key, options
  end
end
