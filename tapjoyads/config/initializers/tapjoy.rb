require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoIPCity.dat")
BANNED_IPS = Set.new(['174.120.96.162', '151.197.180.227', '74.63.224.218', '65.19.143.2'])

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
APP_ID_FOR_DEVICES_REGEX = /^(\w|\.|-)*$/

MASTER_HEALTHZ_FILE = "#{Rails.root}/tmp/master_healthz_status.txt"

# SDK URLs
ANDROID_CONNECT_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v8.1.1.zip'
ANDROID_OFFERS_SDK   = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Android_v8.1.1.zip'
ANDROID_VG_SDK       = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v8.1.1.zip'
ANDROID_UNITY_PLUGIN = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyUnityPlugin_Android_v8.1.1.zip'

IPHONE_CONNECT_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_iOS_v8.1.3.zip'
IPHONE_OFFERS_SDK   = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPublisherSDK_iOS_v8.1.3.zip'
IPHONE_VG_SDK       = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iOS_v8.1.3.zip'
IPHONE_UNITY_PLUGIN = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectUnityPluginSample_8.1.3.zip'

WINDOWS_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/'
WINDOWS_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/'
WINDOWS_VG_SDK      = 'https://s3.amazonaws.com/tapjoy/sdks/'

SCHEMA_VERSION = ActiveRecord::Migrator.current_version

DEV_FORUM_URL = 'https://groups.google.com/group/tapjoy-developer'
KNOWLEDGE_CENTER_URL = 'http://knowledge.tapjoy.com/'
TAPJOY_GAMES_REGISTRATION_OFFER_ID = 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
TAPJOY_GAMES_CURRENT_TOS_VERSION = 2

WEB_REQUEST_LOGGER = SyslogLogger.new("#{RUN_MODE_PREFIX}rails-web_requests")

Mc.cache.flush if CLEAR_MEMCACHE

AWS.config(
  :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :http_handler      => AWS::Core::Http::HTTPartyHandler.new
)

GAMES_CONFIG = YAML::load_file("#{RAILS_ROOT}/config/games.yaml")[Rails.env]

VERTICA_CONFIG = YAML::load_file("#{RAILS_ROOT}/config/vertica.yml")[Rails.env]
