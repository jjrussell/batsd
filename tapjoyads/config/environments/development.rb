begin
  local_config = YAML::load_file("#{Rails.root}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

Tapjoyad::Application.configure do

  config.middleware.use "Rack::Bug", :secret_key => "password"

  config.middleware.use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => :any
    end
  end
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.i18n_js_cache = false
  config.assets.compile = true
  config.assets.debug = true
end

amazon = YAML::load_file("#{Rails.root}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['dev']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['dev']['secret_access_key']
AWS_ACCOUNT_ID = '331510376354'

CACHE_SERVERS                    = {}
CACHE_SERVERS[:analytics_logger] = ['127.0.0.1']
CACHE_SERVERS[:stats]            = ['127.0.0.1']
MEMCACHE_SERVERS                 = ['127.0.0.1']
SDB_MEMCACHE_SERVERS             = ['127.0.0.1']
DISTRIBUTED_MEMCACHE_SERVERS     = ['127.0.0.1']

EXCEPTIONS_NOT_LOGGED = []

if ENV['AUTO_CACHE_MODELS'].present?
  models = ENV['AUTO_CACHE_MODELS']
  AUTO_CACHE_MODELS = (models =~ /^true$/i ? true : models.split(/,\s?/))
end

SPROCKETS_CONFIG = {
  :compile => false,
  :combine => true,
  :host => local_config['asset_host'] || local_config['website_url'] || 'http://localhost:3000'
}

RUN_MODE_PREFIX = 'dev_'
API_URL = local_config['api_url'] || 'http://localhost:3000'
API_URL_EXT = local_config['api_url_ext'] || 'http://localhost:3000'
DASHBOARD_URL = local_config['dashboard_url'] || 'http://localhost:3000'
WEBSITE_URL = local_config['website_url'] || 'http://localhost:3000'
MASTERJOBS_URL = local_config['masterjobs_url'] || 'http://localhost:3000'
CLOUDFRONT_URL = 'https://s3.amazonaws.com/dev_tapjoy'
XMAN = local_config['xman'] || false

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

mail_chimp = YAML::load_file("#{Rails.root}/config/mail_chimp.yaml")['development']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

SYMMETRIC_CRYPTO_SECRET = '63fVhp;QqC8N;cV2A0R.q(@6Vd;6K.\\_'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = '2AdufehEmUpEdrEtamaspuxasU#=De'
CLICK_KEY_SALT = 'nKKliIDdXwDvLaRv3kWYjDkf4lRnvw'

FRESHBOOKS_API_URL = 'tjdev.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '59548f1150fa38c3feb2a67d6b1a0f8b'

PAPAYA_API_URL = 'https://papayamobile.com'
PAPAYA_SECRET = 'RT4oNOKx0QK2nJ51'

CLEAR_MEMCACHE = !(local_config['clear_memcache'] == false)

twitter = YAML::load_file("#{Rails.root}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['dev']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['dev']['consumer_secret']

DEV_FACEBOOK_ID = '100000459598424'

DEVICE_LINK_TRACKING_PIXEL = ''

Sass::Plugin.options[:style] = :nested

TAPJOY_GAMES_INVITATION_OFFER_ID = '8a9e4550-6230-40f4-bd6b-6c376fd37ac3'
TRACKING_OFFER_CURRENCY_ID = '2fa3e3cc-9376-470b-b3f1-b6f5a6369d70'
FLOWDOCK_API_KEY = '3f91ba6016a83d6d5ee4a6c16b484625'

ENV['position_in_class']   = "before"
ENV['exclude_tests']       = "true"
ENV['exclude_fixtures']    = "true"

AMQP_URL = 'amqp://guest:guest@localhost'

ANALYTICS_LOGGER_LEVEL = Logger::FATAL

TIPALTI_PAYEE_API = 'http://int.payrad.com/Payees/'
TIPALTI_PAYER_API_WSDL = 'http://api.payrad.com/PayerFunctions.asmx?WSDL'
TIPALTI_PAYER_NAME = 'Tapjoy'
TIPALTI_ENCRYPTION_SALT = 'TapJoyDemoKey'
