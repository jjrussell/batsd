# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.gem 'factory_girl', :version => '1.3.1'
config.gem 'shoulda', :version => '2.11.1'
config.gem 'shoulda-addons', :version => '0.2.2', :lib => 'shoulda_addons'

MEMCACHE_SERVERS = ['127.0.0.1']

EXCEPTIONS_NOT_LOGGED = []

RUN_MODE_PREFIX = 'test_'
API_URL = ''
CLOUDFRONT_URL = 'https://d21x2jbj16e06e.cloudfront.net'

amazon = YAML::load_file("#{RAILS_ROOT}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['test']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['test']['secret_access_key']

MAX_WEB_REQUEST_DOMAINS = 2
NUM_POINT_PURCHASES_DOMAINS = 2
NUM_CLICK_DOMAINS = 2
NUM_REWARD_DOMAINS = 2
NUM_DEVICES_DOMAINS = 2

mail_chimp = YAML::load_file("#{RAILS_ROOT}/config/mail_chimp.yaml")['test']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

APSALAR_URL = 'https://livebeef42.apsalar.com'
APSALAR_SECRET = 'Tn0oWhQ4k3rahJ45vy4RI3vzausCOoyo'
