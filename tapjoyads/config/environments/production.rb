Tapjoyad::Application.configure do

  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'


  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  # TODO: Fix this with nginx
  config.serve_static_assets = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  config.action_controller.asset_host = "//d2p49qm25dcs4t.cloudfront.net"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.i18n_js_cache = true
  config.assets.compile = true
  config.assets.debug = false
  config.assets.digest = true

  config.tapjoy_api_key = ENV['TAPJOY_API_KEY'] || raise('Please provide an API key')
end

begin
  local_config = YAML::load_file("#{Rails.root}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

CACHE_SERVERS = {}
CACHE_SERVERS[:analytics_logger] = [
  'rabbit-dedupe.tapjoy.net'
]
CACHE_SERVERS[:stats] = [
  'tj-prod-20120424.fqfjqv.0001.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0002.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0003.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0004.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0005.use1.cache.amazonaws.com' # couchbase stats cluster
]
CACHE_SERVERS[:dedupe] = [
  'queues-dedupe-0.tapjoy.local',
  'queues-dedupe-1.tapjoy.local',
  'queues-dedupe-2.tapjoy.local'
]
MEMCACHE_SERVERS = [
  'tj-prod-20120424.fqfjqv.0001.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0002.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0003.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0004.use1.cache.amazonaws.com',
  'tj-prod-20120424.fqfjqv.0005.use1.cache.amazonaws.com'
]
SDB_MEMCACHE_SERVERS = [
  'tj-sdb-20120912.fqfjqv.0001.use1.cache.amazonaws.com',
  'tj-sdb-20120912.fqfjqv.0002.use1.cache.amazonaws.com',
  'tj-sdb-20120912.fqfjqv.0004.use1.cache.amazonaws.com',
  'tj-sdb-20120912.fqfjqv.0005.use1.cache.amazonaws.com',
  'tj-sdb-20120912.fqfjqv.0006.use1.cache.amazonaws.com',
]
DISTRIBUTED_MEMCACHE_SERVERS = [
  'localhost:21210', # couchbase us-east-1b
  'localhost:21211', # couchbase us-east-1c
  'localhost:21212', # couchbase us-east-1d
  'localhost:21213', # couchbase us-east-1e
]

SPROCKETS_CONFIG = {
  :compile => true,
  :combine => true,
  :host => local_config['asset_host'] || local_config['website_url'] || 'https://d2mlgzrlqoz88m.cloudfront.net'
}

RUN_MODE_PREFIX = ''
API_URL = local_config['api_url'] || 'https://ws.tapjoyads.com'
API_URL_EXT = local_config['api_url_ext'] || 'http://ws-ext.tapjoy.com'
DASHBOARD_URL = local_config['dashboard_url'] || 'https://dashboard.tapjoy.com'
WEBSITE_URL = local_config['website_url'] || 'https://www.tapjoy.com'
MASTERJOBS_URL = local_config['masterjobs_url'] || 'https://masterjobs.tapjoy.net'
CLOUDFRONT_URL = 'https://d21x2jbj16e06e.cloudfront.net'
XMAN = false

# Amazon services:
amazon = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['production']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['production']['secret_access_key']
AWS_ACCOUNT_ID = '266171351246'

NUM_POINT_PURCHASES_DOMAINS = 10
NUM_CLICK_DOMAINS = 100
NUM_REWARD_DOMAINS = 50
NUM_DEVICES_DOMAINS = 300
NUM_DEVICE_IDENTIFIER_DOMAINS = 100
NUM_TEMPORARY_DEVICE_DOMAINS = 10
NUM_GAME_STATE_DOMAINS = 300
NUM_GAME_STATE_MAPPING_DOMAINS = 10
NUM_PUBLISHER_USER_DOMAINS = 50
NUM_CONVERSION_ATTEMPT_DOMAINS = 50
NUM_RISK_PROFILE_DOMAINS = 100

mail_chimp = YAML::load_file("#{Rails.root}/config/mail_chimp.yaml")['production']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

sendgrid = YAML::load_file("#{Rails.root}/config/sendgrid.yaml")['production']
SENDGRID_USER = sendgrid['user']
SENDGRID_PASSWD = sendgrid['passwd']

SYMMETRIC_CRYPTO_SECRET = 'YI,B&nZVZQtl*YRDYpEjVE&\U\#jL2!H#H&*2d'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'Z*Xac$dum8xeB9-Quv3St@RET6E6UT'
CLICK_KEY_SALT = 'qEKa5TabzRTryO2BpFcR8s6qwFvB4i'

FRESHBOOKS_API_URL = 'tapjoy.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '26c1ce82ad1cfab698746e532361f814'

PAPAYA_API_URL = 'https://papayamobile.com'
PAPAYA_SECRET = 'RT4oNOKx0QK2nJ51'

CLEAR_MEMCACHE = false

twitter = YAML::load_file("#{::Rails.root.to_s}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['production']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['production']['consumer_secret']

DEVICE_LINK_TRACKING_PIXEL = 'http://tapjoy.go2cloud.org/SL2P'

Sass::Plugin.options[:style] = :compressed

TAPJOY_GAMES_INVITATION_OFFER_ID = '114d3e0c-c8f3-4f42-b016-2b2f81723cd8'
TRACKING_OFFER_CURRENCY_ID = '2fa3e3cc-9376-470b-b3f1-b6f5a6369d70'
FLOWDOCK_API_KEY = 'b052631b6c90acb40c45cb0076eb8afe'

AMQP_URL = 'amqp://tapjoy:Tapjoy123!@rabbit.tapjoy.net'

ANALYTICS_LOGGER_LEVEL = Logger::DEBUG

TIPALTI_PAYEE_API = 'https://ui.tipalti.com/Payees/'
TIPALTI_PAYER_API_WSDL = 'https://api.tipalti.com/PayerFunctions.asmx?WSDL'
TIPALTI_PAYER_NAME = 'Tapjoy'
TIPALTI_ENCRYPTION_SALT = 'spAtUbrarebaStuCebRek5febr9rega8pEnaSp968b29a3rUna7'

RIAK_NODES = [{:host => 'cluster-1.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-2.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-3.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-4.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-5.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-6.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-7.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-8.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-9.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-10.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-11.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-12.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-13.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-14.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-15.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-16.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-17.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-18.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-19.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-20.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-21.us-east-e.riak.tapjoy.net'},
              {:host => 'cluster-22.us-east-e.riak.tapjoy.net'}]
