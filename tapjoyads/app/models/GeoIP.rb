class GeoIP < SimpledbResource
  def initialize(key, load = true)
    super 'geo-ip', key, load  
  end
end