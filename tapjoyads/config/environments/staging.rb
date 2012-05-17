MACHINE_TYPE = nil

Tapjoyad::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  %w( web api job dashboard website legacy ).each do |route|
    config.paths.config.routes << Rails.root.join("config/routes/#{route}.rb")
  end
end

MEMCACHE_SERVERS             = ['127.0.0.1']
DISTRIBUTED_MEMCACHE_SERVERS = ['127.0.0.1']

EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']

begin
  local_config = YAML::load_file("#{Rails.root}/config/local.yml")
rescue Errno::ENOENT
  local_config = {}
end

SPROCKETS_CONFIG = {
  :compile => true,
  :combine => true,
  :host => local_config['asset_host'] || local_config['website_url'] || 'http://d10hyk8bs4mjhv.cloudfront.net'
}

RUN_MODE_PREFIX = 'staging_'
API_URL = local_config['api_url'] || 'http://localhost:3000'
DASHBOARD_URL = local_config['dashboard_url'] || 'http://localhost:3000'
WEBSITE_URL = local_config['website_url'] || 'http://localhost:3000'
CLOUDFRONT_URL = 'https://s3.amazonaws.com/staging_tapjoy'
XMAN = false

# Amazon services:
amazon = YAML::load_file("#{Rails.root}/config/amazon.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['staging']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['staging']['secret_access_key']
AWS_ACCOUNT_ID = '331510376354'

NUM_POINT_PURCHASES_DOMAINS = 2
NUM_CLICK_DOMAINS = 2
NUM_REWARD_DOMAINS = 2
NUM_DEVICES_DOMAINS = 2
NUM_DEVICE_IDENTIFIER_DOMAINS = 2
NUM_GAME_STATE_DOMAINS = 2
NUM_GAME_STATE_MAPPING_DOMAINS = 2
NUM_PUBLISHER_USER_DOMAINS = 2

mail_chimp = YAML::load_file("#{Rails.root}/config/mail_chimp.yaml")['staging']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

SYMMETRIC_CRYPTO_SECRET = '63fVhp;QqC8N;cV2A0R.q(@6Vd;6K.\\_'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'a#X4cHdun84eB9=2bv3fG^RjNe46$T'

FRESHBOOKS_API_URL = 'tjdev.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '59548f1150fa38c3feb2a67d6b1a0f8b'

CLEAR_MEMCACHE = false

twitter = YAML::load_file("#{Rails.root}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['staging']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['staging']['consumer_secret']

DEV_FACEBOOK_ID = '100000459598424'

DEVICE_LINK_TRACKING_PIXEL = 'http://tapjoy.go2cloud.org/SL2P'

Sass::Plugin.options[:style] = :compressed

TAPJOY_GAMES_INVITATION_OFFER_ID = '3839e884-2310-4de4-873f-8b0ca44c1a1a'
TRACKING_OFFER_CURRENCY_ID = '2fa3e3cc-9376-470b-b3f1-b6f5a6369d70'
