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

# Disable request forgery protection because this is an api
config.action_controller.allow_forgery_protection    = false

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

MEMCACHE_SERVERS = [ '10.220.26.177' , '10.220.25.146',
                     '10.222.251.112', '10.222.251.127', '10.125.9.175'  , '10.122.82.14' ,
                     '10.252.27.47'  , '10.252.218.239', '10.122.118.239', '10.122.59.44' ,
                     '10.220.105.220', '10.127.121.53' , '10.253.201.204', '10.252.90.47' ,
                     '10.122.206.240', '10.222.206.47' , '10.252.214.32' , '10.122.79.196' ]

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

RUN_MODE_PREFIX = ''
API_URL = 'https://ws.tapjoyads.com'
CLOUDFRONT_URL = 'https://d21x2jbj16e06e.cloudfront.net'

# Amazon services:
amazon = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['production']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['production']['secret_access_key']

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']

MAX_WEB_REQUEST_DOMAINS = 100
NUM_POINT_PURCHASES_DOMAINS = 10
NUM_CLICK_DOMAINS = 50
NUM_REWARD_DOMAINS = 50
NUM_DEVICES_DOMAINS = 300

mail_chimp = YAML::load_file("#{RAILS_ROOT}/config/mail_chimp.yaml")['production']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']
