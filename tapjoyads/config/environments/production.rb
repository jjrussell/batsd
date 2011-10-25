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

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

MEMCACHE_SERVERS = [ 'tj-acs-prod.fqfjqv.1xm3.use1.acsvc.amazonaws.com',
                     'tj-acs-prod.fqfjqv.1xm4.use1.acsvc.amazonaws.com',
                     'tj-acs-prod.fqfjqv.1xm5.use1.acsvc.amazonaws.com',
                     'tj-acs-prod.fqfjqv.1xm6.use1.acsvc.amazonaws.com' ]

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

begin
  local_config = YAML::load_file("#{RAILS_ROOT}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

RUN_MODE_PREFIX = ''
API_URL = local_config['api_url'] || 'https://ws.tapjoyads.com'
DASHBOARD_URL = local_config['dashboard_url'] || 'https://dashboard.tapjoy.com'
WEBSITE_URL = local_config['website_url'] || 'https://www.tapjoy.com'
CLOUDFRONT_URL = 'https://d21x2jbj16e06e.cloudfront.net'
GAMES_ANDROID_MARKET_URL = 'http://market.android.com/details?id=com.tapjoy.tapjoy'
TJGAMES_URL = local_config['tjgames_url'] || 'https://www.tapjoygames.com'

# Amazon services:
amazon = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['production']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['production']['secret_access_key']

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']

NUM_POINT_PURCHASES_DOMAINS = 10
NUM_CLICK_DOMAINS = 50
NUM_REWARD_DOMAINS = 50
NUM_DEVICES_DOMAINS = 300
NUM_GAME_STATE_DOMAINS = 2
NUM_GAME_STATE_MAPPING_DOMAINS = 10
NUM_PUBLISHER_USER_DOMAINS = 50

mail_chimp = YAML::load_file("#{RAILS_ROOT}/config/mail_chimp.yaml")['production']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

SYMMETRIC_CRYPTO_SECRET = 'YI,B&nZVZQtl*YRDYpEjVE&\U\#jL2!H#H&*2d'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'Z*Xac$dum8xeB9-Quv3St@RET6E6UT'

FRESHBOOKS_API_URL = 'tapjoy.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '26c1ce82ad1cfab698746e532361f814'

CLEAR_MEMCACHE = false

twitter = YAML::load_file("#{RAILS_ROOT}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['production']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['production']['consumer_secret']
