require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoLiteCity.dat")

unless Rails.env == 'production'
  Mc.cache.flush
end
