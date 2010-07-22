require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoLiteCity.dat")

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

unless Rails.env == 'production'
  Mc.cache.flush
end
