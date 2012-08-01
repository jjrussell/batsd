require 'extensions'
require 'notifier'

GEOIP_VERSION = `cat #{Rails.root}/data/GeoIPCity.version`
# I kinda fucked this up, but it's already deployed with the - in it
# This basically makes it work with dev systems that only have the regular
# .dat file.
geoip_tag = (GEOIP_VERSION == '' ? '' : '-')
GEOIP = GeoIP.new("#{Rails.root}/data/#{GEOIP_VERSION}#{geoip_tag}GeoIPCity.dat")
BANNED_IPS = Set.new(['174.120.96.162', '151.197.180.227', '74.63.224.218', '65.19.143.2'])
BANNED_UDIDS = Set.new(['358673013795895', '0304c63f3624dbb8fab792f24e6d3f79dd78442031e27e5e8c892d7155f024a8', # UDID and SHA2 of that UDID in pairs.
  '004999010640000', '45ace52a5a817f345a6849dcf5f2ed01d26bcea38cd6f73b6439a1398ead513a',
  '012345678901237', 'f413dceae5ffc62ade872a6697e31a23d43b3e3c83ad45303c6e63e8cfb0a1e4',
  '355195000000017', '6f2493936ac99c3068d4da6eca711926c496df66500362dceb4b745a63084cf5'])

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
APP_ID_FOR_DEVICES_REGEX = /^(\w|\.|-)*$/

MASTER_HEALTHZ_FILE = "#{Rails.root}/tmp/master_healthz_status.txt"
EPHEMERAL_HEALTHZ_FILE = "#{Rails.root}/tmp/eph_test.txt"

# SDK URLs
ANDROID_CONNECT_SDK         = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v8.2.2.zip'
ANDROID_OFFERS_SDK          = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Android_v8.2.2.zip'
ANDROID_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v8.2.2.zip'
ANDROID_UNITY_PLUGIN        = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyUnityPlugin_Android_v8.2.2.zip'
ANDROID_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPhoneGapPlugin_Android_v8.2.2.zip'
ANDROID_MARMALADE_EXTENSION = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyMarmaladePlugin_Android_v8.2.2.zip'

IPHONE_CONNECT_SDK         = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_iOS_v8.2.0.zip'
IPHONE_OFFERS_SDK          = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPublisherSDK_iOS_v8.2.0.zip'
IPHONE_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iOS_v8.2.0.zip'
IPHONE_UNITY_PLUGIN        = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectUnityPluginSample_v8.2.0.zip'
IPHONE_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPhoneGapPluginSample_v8.2.0.zip'
IPHONE_MARMALADE_EXTENSION = 'https://github.com/downloads/marmalade/Tapjoy-for-Marmalade/Tapjoy_iOS.zip'
IPHONE_ADOBE_AIR_PLUGIN    = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectAdobeAIRPlugin_v8.2.0.zip'

WINDOWS_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyAdvertiserSDK_Windows_v2.0.1.zip'
WINDOWS_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Windows_v2.0.1.zip'

SDKLESS_MIN_LIBRARY_VERSION = '8.2.0'

DEV_FORUM_URL = 'https://groups.google.com/group/tapjoy-developer'
KNOWLEDGE_CENTER_URL = 'http://knowledge.tapjoy.com/'
TAPJOY_GAMES_REGISTRATION_OFFER_ID = 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
TAPJOY_GAMES_CURRENT_TOS_VERSION = 2
TAPJOY_PARTNER_ID = '70f54c6d-f078-426c-8113-d6e43ac06c6d'
RECEIPT_EMAIL = 'email.receipts@tapjoy.com'
GAMES_ANDROID_MARKET_URL = 'https://play.google.com/store/apps/details?id=com.tapjoy.tapjoy'

SYSLOG_NG_LOGGER = SyslogLogger.new("#{RUN_MODE_PREFIX}rails-web_requests")

Mc.cache.flush if CLEAR_MEMCACHE

AWS.config(
  :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :http_handler      => AWS::Core::Http::HTTPartyHandler.new
)

GAMES_CONFIG = YAML::load_file("#{Rails.root}/config/games.yaml")[Rails.env]
MARKETPLACE_CONFIG = YAML::load_file("#{Rails.root}/config/marketplace.yaml")[Rails.env]

Sprockets::Tj.init_assets

VERTICA_CONFIG = YAML::load_file("#{Rails.root}/config/vertica.yml")[Rails.env]

TEXTFREE_PUB_APP_ID = '6b69461a-949a-49ba-b612-94c8e7589642'

BLANK_IMAGE = 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='

TJM_SESSION_TIMEOUT = 1.hour.to_i

HOSTNAME = `hostname`.strip

Dir.chdir Rails.root do
  GIT_REV = `git rev-parse --verify HEAD`.strip
  GIT_BRANCH = `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`.split.last.strip rescue ''
end

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']
