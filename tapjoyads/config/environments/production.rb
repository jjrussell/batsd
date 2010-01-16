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

MEMCACHE_SERVERS = ['10.254.203.164',
                    '10.210.185.220',
                    
                    '10.241.35.51',
                    '10.240.58.197',
                    '10.241.29.206',
                    '10.240.85.188',
                    '10.240.93.139']

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

RUN_MODE_PREFIX = ''

REDIRECT_URI = 'http://webservice-lb-624573684.us-east-1.elb.amazonaws.com/'

MAX_DEVICE_APP_DOMAINS = 10
MAX_WEB_REQUEST_DOMAINS = 10