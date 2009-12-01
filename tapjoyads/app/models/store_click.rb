##
# Represents a single click to the app store.
class StoreClick < SimpledbResource
  
  def initialize(key, options = {})
    super 'store-click', key, options
  end
end