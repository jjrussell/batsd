require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoLiteCity.dat")

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
APP_ID_FOR_DEVICES_REGEX = /^(\w|\.|-)*$/

MASTER_HEALTHZ_FILE = "#{Rails.root}/tmp/master_healthz_status.txt"

# SDK URLs
ANDROID_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v8.0.0.zip'
ANDROID_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyOffersSDK_Android_v8.0.0.zip'
ANDROID_VG_SDK      = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v8.0.0.zip'

IPHONE_CONNECT_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_iOS_v8.0.0.zip'
IPHONE_OFFERS_SDK   = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectOffersSDK_iOS_v8.0.0.zip'
IPHONE_VG_SDK       = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iOS_v8.0.0.zip'
IPHONE_UNITY_PLUGIN = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectUnityPluginSample.zip'

#TODO fill this out
WINDOWS_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/'
WINDOWS_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/'
WINDOWS_VG_SDK      = 'https://s3.amazonaws.com/tapjoy/sdks/'

unless Rails.env == 'production'
  Mc.cache.flush
end
