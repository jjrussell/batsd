##
# Represents a single showing of an offer wall.
class OfferWall < SimpledbResource
  
  def initialize(options = {})
    key = UUIDTools::UUID.random_create.to_s
    super 'offer_wall', key, options
  end
end
