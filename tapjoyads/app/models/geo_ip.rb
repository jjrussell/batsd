class GeoIP < SimpledbResource
  def initialize(key, options = {})
    super 'geo-ip', key, options  
  end
end