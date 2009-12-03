class CachedOffer < SimpledbResource
  def initialize(key, load = true)
    super 'cached-offer', key, load
  end
end