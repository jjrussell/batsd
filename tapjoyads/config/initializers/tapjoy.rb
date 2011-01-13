require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoLiteCity.dat")

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

# SDK URLs
ANDROID_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v7.1.0.zip'
ANDROID_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyOffersSDK_Android_v7.1.0.zip'
ANDROID_VG_SDK      = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v7.1.0.zip'
IPHONE_CONNECT_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_iPhone_v7.3.1.zip'
IPHONE_OFFERS_SDK   = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectOffersSDK_iPhone_v7.3.1.zip'
IPHONE_VG_SDK       = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iPhone_v7.3.1.zip'

unless Rails.env == 'production'
  Mc.cache.flush
end
