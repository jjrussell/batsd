##
# Represents a single click for an offer
class OfferClick < SimpledbResource
  
  def initialize(key, options = {})
    super 'offer-click', key, options
  end
end