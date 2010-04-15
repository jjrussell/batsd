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

MEMCACHE_SERVERS = ['10.241.35.51',
                    '10.240.58.197',
                    '10.241.29.206',
                    '10.240.85.188',
                    '10.240.93.139',
                    '10.240.54.244',
                    '10.241.31.239',
                    '10.240.58.181',
                    '10.240.246.16',
                    '10.240.15.207',
                    '10.209.94.175',
                    '10.209.213.210',
                    '10.209.197.174',
                    '10.209.99.177',
                    '10.240.15.229',
                    '10.248.99.102',
                    '10.248.107.133',
                    '10.249.74.97',
                    '10.249.114.224',
                    '10.249.126.97',
                    '10.254.142.178',
                    '10.211.34.175',
                    '10.192.167.147',
                    '10.215.83.229',
                    '10.215.82.229']

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

RUN_MODE_PREFIX = ''

REDIRECT_URI = 'http://webservice-lb-624573684.us-east-1.elb.amazonaws.com/'

# Amazon services:
amazon = YAML::load_file("#{RAILS_ROOT}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['main']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['main']['secret_access_key']

# AWS S3:
require 'aws/s3'
AWS::S3::Base.establish_connection!(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])

# Add "RightAws::AwsError: sdb.amazonaws.com temporarily unavailable: (getaddrinfo: Temporary failure in name resolution)"
# to the list of transient problems which will automatically get retried by RightAws.
require 'right_aws'
RightAws::RightAwsBase.amazon_problems = RightAws::RightAwsBase.amazon_problems | ['temporarily unavailable', 'InvalidClientTokenId', 'InternalError', 'QueryTimeout']

MAX_DEVICE_APP_DOMAINS = 20
MAX_WEB_REQUEST_DOMAINS = 15
NUM_POINT_PURCHASES_DOMAINS = 10