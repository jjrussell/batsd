##
# Represents a single click to the app store.
class StoreClick < SimpledbResource
  
  def initialize(key, load = true)
    domain_name = "store-click"
    
    super domain_name, key, load
  end
end