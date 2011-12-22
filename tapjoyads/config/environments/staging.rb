# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# Disable request forgery protection because this is an api
config.action_controller.allow_forgery_protection    = false

config.gem 'mail_safe', :version => '0.3.1'

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

MEMCACHE_SERVERS = [ '127.0.0.1' ]

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

begin
  local_config = YAML::load_file("#{RAILS_ROOT}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

RUN_MODE_PREFIX = 'staging_'
API_URL = local_config['api_url'] || 'http://localhost:3000'
DASHBOARD_URL = local_config['dashboard_url'] || 'http://localhost:3000'
WEBSITE_URL = local_config['website_url'] || 'http://localhost:3000'
CLOUDFRONT_URL = 'https://s3.amazonaws.com/staging_tapjoy'
GAMES_ANDROID_MARKET_URL = 'http://market.android.com/details?id=com.tapjoy.tapjoy'

# Amazon services:
amazon = YAML::load_file("#{RAILS_ROOT}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['staging']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['staging']['secret_access_key']
AWS_ACCOUNT_ID = '331510376354'

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']

NUM_POINT_PURCHASES_DOMAINS = 2
NUM_CLICK_DOMAINS = 2
NUM_REWARD_DOMAINS = 2
NUM_DEVICES_DOMAINS = 2
NUM_GAME_STATE_DOMAINS = 2
NUM_GAME_STATE_MAPPING_DOMAINS = 2
NUM_PUBLISHER_USER_DOMAINS = 2

mail_chimp = YAML::load_file("#{RAILS_ROOT}/config/mail_chimp.yaml")['staging']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

send_grid = YAML::load_file("#{RAILS_ROOT}/config/send_grid.yaml")['staging']
SEND_GRID_USER = send_grid['user']
SEND_GRID_PASSWD = send_grid['passwd']

SYMMETRIC_CRYPTO_SECRET = '63fVhp;QqC8N;cV2A0R.q(@6Vd;6K.\\_'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'a#X4cHdun84eB9=2bv3fG^RjNe46$T'

FRESHBOOKS_API_URL = 'tjdev.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '59548f1150fa38c3feb2a67d6b1a0f8b'

CLEAR_MEMCACHE = false

DEV_FACEBOOK_ID = '100000459598424'

DEVICE_LINK_TRACKING_PIXEL = 'http://tapjoy.go2cloud.org/SL2P'

Sass::Plugin.options[:style] = :compressed
