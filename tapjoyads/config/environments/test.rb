Dotenv.load

Tapjoyad::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  config.time_zone = 'UTC'

  config.i18n_js_cache = true
end

mc_host_array                            = [ENV['MEMCACHED_HOST'] || '127.0.0.1']
CACHE_SERVERS                            = {}
CACHE_SERVERS[:analytics_logger]         = mc_host_array
CACHE_SERVERS[:stats]                    = mc_host_array
CACHE_SERVERS[:dedupe]                   = mc_host_array
MEMCACHE_SERVERS                         = mc_host_array
SDB_MEMCACHE_SERVERS                     = mc_host_array
PRIMARY_DISTRIBUTED_COUCHBASE_CLUSTER    = mc_host_array
SECONDARY_DISTRIBUTED_COUCHBASE_CLUSTERS = []

EXCEPTIONS_NOT_LOGGED = []

begin
  local_config = YAML::load_file("#{Rails.root}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

SPROCKETS_CONFIG = {
  :compile => false,
  :combine => false,
  :host => local_config['asset_host'] || local_config['website_url'] || 'http://localhost:3000'
}

if ENV['CUCUMBER']
  RUN_MODE_PREFIX = "test_"
else
  RUN_MODE_PREFIX = "test_#{Time.now.to_i % 20}_"
end

API_URL = local_config['api_url'] || 'http://localhost:3000'
API_URL_EXT = local_config['api_url_ext'] || 'http://localhost:3000'
DASHBOARD_URL = local_config['dashboard_url'] || 'http://localhost:3000'
WEBSITE_URL = local_config['website_url'] || 'http://localhost:3000'
MASTERJOBS_URL = local_config['masterjobs_url'] || 'http://localhost:3000'
CLOUDFRONT_URL = "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"
XMAN = false

amazon = YAML::load_file("#{Rails.root}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['test']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['test']['secret_access_key']
AWS_ACCOUNT_ID = '331510376354'

NUM_POINT_PURCHASES_DOMAINS = 2
NUM_CLICK_DOMAINS = 2
NUM_REWARD_DOMAINS = 2
NUM_DEVICES_DOMAINS = 2
NUM_DEVICE_IDENTIFIER_DOMAINS = 2
NUM_TEMPORARY_DEVICE_DOMAINS = 2
NUM_GAME_STATE_DOMAINS = 2
NUM_GAME_STATE_MAPPING_DOMAINS = 2
NUM_PUBLISHER_USER_DOMAINS = 2
NUM_CONVERSION_ATTEMPT_DOMAINS = 2
NUM_RISK_PROFILE_DOMAINS = 2

mail_chimp = YAML::load_file("#{Rails.root}/config/mail_chimp.yaml")['test']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

SYMMETRIC_CRYPTO_SECRET = '63fVhp;QqC8N;cV2A0R.q(@6Vd;6K.\\_'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'yeJaf+ux5W!a_62eZacra9ep8w@Z&?'
CLICK_KEY_SALT = 'nKKliIDdXwDvLaRv3kWYjDkf4lRnvw'

FRESHBOOKS_API_URL = 'tjdev.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '59548f1150fa38c3feb2a67d6b1a0f8b'

PAPAYA_API_URL = 'https://papayamobile.com'
PAPAYA_SECRET = 'RT4oNOKx0QK2nJ51'

CLEAR_MEMCACHE = true

twitter = YAML::load_file("#{Rails.root}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['test']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['test']['consumer_secret']

DEV_FACEBOOK_ID = '100000459598424'

DEVICE_LINK_TRACKING_PIXEL = ''

TAPJOY_GAMES_INVITATION_OFFER_ID = '8a9e4550-6230-40f4-bd6b-6c376fd37ac3'
TRACKING_OFFER_CURRENCY_ID = '2fa3e3cc-9376-470b-b3f1-b6f5a6369d70'
FLOWDOCK_API_KEY = '3f91ba6016a83d6d5ee4a6c16b484625'

AMQP_URL = 'amqp://guest:guest@localhost'

ANALYTICS_LOGGER_LEVEL = Logger::FATAL

TIPALTI_PAYEE_API = 'http://int.payrad.com/Payees/'
TIPALTI_PAYER_API_WSDL = 'http://api.payrad.com/PayerFunctions.asmx?WSDL'
TIPALTI_PAYER_NAME = 'Tapjoy'
TIPALTI_ENCRYPTION_SALT = 'TapJoyDemoKey'
