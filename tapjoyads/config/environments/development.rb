# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

amazon = YAML::load_file("#{RAILS_ROOT}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['dev']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['dev']['secret_access_key']

# AWS S3:
require 'aws/s3'
AWS::S3::Base.establish_connection!(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
    

MEMCACHE_SERVERS = ['127.0.0.1']

EXCEPTIONS_NOT_LOGGED = []

RUN_MODE_PREFIX = 'test_'

REDIRECT_URI = 'http://localhost:3000/'

MAX_DEVICE_APP_DOMAINS = 3
MAX_WEB_REQUEST_DOMAINS = 2
NUM_POINT_PURCHASES_DOMAINS = 2
