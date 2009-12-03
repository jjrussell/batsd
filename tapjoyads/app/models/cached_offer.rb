class CachedOffer < SimpledbResource
  def initialize(key, options = {}
    super 'cached-offer', key, options
  end
end