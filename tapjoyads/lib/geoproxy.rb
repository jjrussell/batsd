# Wraps/ proxies GeoIP so that we have a way to call reconnect! on it in an after_fork hook
class Geoproxy
  def initialize(path)
    @path = path
    self.reconnect!
  end
  def reconnect!
    @geoip = GeoIP.new( @path )
  end
  def method_missing *args
    @geoip.send *args
  end
end
