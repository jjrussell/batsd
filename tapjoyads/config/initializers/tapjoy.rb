require 'extensions'
require 'notifier'
require 'exact_target'

GEOIP_VERSION = `cat #{Rails.root}/data/GeoIPCity.version`
# I kinda fucked this up, but it's already deployed with the - in it
# This basically makes it work with dev systems that only have the regular
# .dat file.
geoip_tag = (GEOIP_VERSION == '' ? '' : '-')
GEOIP = Geoproxy.new("#{Rails.root}/data/#{GEOIP_VERSION}#{geoip_tag}GeoIPCity.dat")

#TODO: make this configurable without a code change
BANNED_IPS = Set.new(['174.120.96.162', '151.197.180.227', '74.63.224.218', '65.19.143.2', '67.164.98.72', '67.180.48.106'])
BANNED_UDIDS = Set.new(['004999010640000', '45ace52a5a817f345a6849dcf5f2ed01d26bcea38cd6f73b6439a1398ead513a', #UDID and SHA2 of that UDID in pairs.
                        '012345678901234', 'd245de8f862b8f166024c1c4e1a0ce41ec03c33dd9cd2d203487e8cef4b5a061',
                        '012345678901237', 'f413dceae5ffc62ade872a6697e31a23d43b3e3c83ad45303c6e63e8cfb0a1e4',
                        '352005048247251', 'cafc5c408c7aaa5b1626169964b69be08792d4fe75a0f4a8b062dd7c8bbdebb2',
                        '355195000000017', '6f2493936ac99c3068d4da6eca711926c496df66500362dceb4b745a63084cf5',
                        '358673013795895', '0304c63f3624dbb8fab792f24e6d3f79dd78442031e27e5e8c892d7155f024a8',
                        'a22aaa22-a2aa-2aa2-aa2a-a2aaa2aa2a2a', '0123456789abcdef', '88508850885050'])
IGNORED_UDIDS = Set.new([
  '00000000',
  '000000000000000',
  '001068000000006',
  '111111111111119',
  '12345678',
  '123456789012345',
  '351869058577423',
  '352273017386340',
  '352751019523267',
  '355692547693084',
  '357070003178961',
  '88508850885050',
  'a22aaa22-a2aa-2aa2-aa2a-a2aaa2aa2a2a',
  'armeabi-v7a',
  'd01e',
  'espresso10wifi',
  'espressowifi',
  'grouper',
  'iml74k',
  'jro03c',
  'msm7627a',
  'none',
  'null',
  'unknown',
])

IGNORED_ADVERTISING_IDS = Set.new([
  '00000000-0000-0000-0000-000000000000',
])

APP_ID_FOR_DEVICES_REGEX = /^(\w|\.|-)*$/

MASTER_HEALTHZ_FILE = "#{Rails.root}/tmp/master_healthz_status.txt"
EPHEMERAL_HEALTHZ_FILE = "#{Rails.root}/tmp/eph_test.txt"

# SDK URLs
ANDROID_CONNECT_SDK         = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v9.0.0.zip'
ANDROID_OFFERS_SDK          = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Android_v9.0.0.zip'
ANDROID_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v8.3.0.zip'
ANDROID_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPhoneGapPlugin_Android_v8.3.1.zip'
ANDROID_MARMALADE_EXTENSION = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyMarmaladePlugin_Android_v8.2.2.zip'

IPHONE_CONNECT_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyAdvertiserSDK_iOS_v9.0.0.zip'
IPHONE_CONNECT_SDK_UDID_OPT_OUT = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyAdvertiserSDK_iOS_v9.0.0_UDIDOptOut.zip'
IPHONE_OFFERS_SDK               = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_iOS_v9.0.0.zip'
IPHONE_OFFERS_SDK_UDID_OPT_OUT  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_iOS_v9.0.0_UDIDOptOut.zip'
IPHONE_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iOS_v8.3.2.zip'
IPHONE_UNITY_PLUGIN        = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyUnityPlugin_v9.0.0.zip'
IPHONE_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPhoneGapPluginSample_v8.3.2.zip'
IPHONE_MARMALADE_EXTENSION = 'https://github.com/downloads/marmalade/Tapjoy-for-Marmalade/Tapjoy_iOS.zip'
IPHONE_ADOBE_AIR_PLUGIN    = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectAdobeAIRPlugin_v8.3.3.zip'

WINDOWS_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyAdvertiserSDK_Windows_v2.0.1.zip'
WINDOWS_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Windows_v2.0.1.zip'

SDKLESS_MIN_LIBRARY_VERSION = '8.2.0'

DEV_FORUM_URL = 'https://groups.google.com/group/tapjoy-developer'
KNOWLEDGE_CENTER_URL = 'https://kc.tapjoy.com/'
TAPJOY_GAMES_REGISTRATION_OFFER_ID = 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID = '609f5b88-80a9-48a7-ac98-d2a304bf9952'
TAPJOY_GAMES_CURRENT_TOS_VERSION = 2
TAPJOY_PARTNER_ID = '70f54c6d-f078-426c-8113-d6e43ac06c6d'
TAPJOY_SURVEY_PARTNER_ID = '94784f5e-fd63-4897-a759-9850965695bf'
TAPJOY_ACCOUNTING_PARTNER_IDS = [TAPJOY_PARTNER_ID, TAPJOY_SURVEY_PARTNER_ID]
RECEIPT_EMAIL = 'email.receipts@tapjoy.com'
GAMES_ANDROID_MARKET_URL = 'https://play.google.com/store/apps/details?id=com.tapjoy.tapjoy'

Mc.cache.flush if CLEAR_MEMCACHE

AWS.config(
  :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :http_handler      => AWS::Core::Http::HTTPartyHandler.new
)

VERTICA_CONFIG = YAML::load_file("#{Rails.root}/config/vertica.yml")[Rails.env]

TEXTFREE_PUB_APP_ID = '6b69461a-949a-49ba-b612-94c8e7589642'

BLANK_IMAGE = 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='

TJM_SESSION_TIMEOUT = 1.hour.to_i

HOSTNAME = `hostname`.strip

Dir.chdir Rails.root do
  GIT_REV = begin
      show = `git show --decorate HEAD | head -n 1`.strip
      tag = show.match(/tag: (\d+)/)
      commit = show.match(/commit (\w+)/)
      tag ? tag[1] : (commit ? commit[1][0,7] : '')
    rescue
      ''
    end
  GIT_BRANCH = `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`.split.last.strip rescue ''
end

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']

AnalyticsLogger.default_message_data = {:hostname => HOSTNAME}
