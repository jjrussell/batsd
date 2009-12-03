##
# Represents a single click for an offer
class OfferClick < SimpledbResource
  
  def initialize(key, load = true)
    domain_name = "offer-click"
    
    super domain_name, key, load
  end
end