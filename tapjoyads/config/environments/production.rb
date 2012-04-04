MACHINE_TYPE = `"#{Rails.root}/../server/server_type.rb"`

Tapjoyads::Application.configure do

  routes = case MACHINE_TYPE
           when 'dashboard'
             %w( dashboard sdk )
           when 'website'
             %w( website sdk )
           when 'web'
             %w( web legacy )
           else
             %w( sdk dashboard website web legacy )
           end

  routes.each do |route|
    config.paths.config.routes << Rails.root.join("config/routes/#{route}.rb")
  end

  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
SPROCKETS_CONFIG = {
  :compile => true,
  :combine => true,
  :host => local_config['asset_host'] || local_config['website_url'] || 'https://d2mlgzrlqoz88m.cloudfront.net'
}

RUN_MODE_PREFIX = ''
API_URL = local_config['api_url'] || 'https://ws.tapjoyads.com'
DASHBOARD_URL = local_config['dashboard_url'] || 'https://dashboard.tapjoy.com'
WEBSITE_URL = local_config['website_url'] || 'https://www.tapjoy.com'
CLOUDFRONT_URL = 'https://d21x2jbj16e06e.cloudfront.net'

# Amazon services:
amazon = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
ENV['AWS_ACCESS_KEY_ID'] = amazon['production']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = amazon['production']['secret_access_key']
AWS_ACCOUNT_ID = '266171351246'

NUM_POINT_PURCHASES_DOMAINS = 10
NUM_CLICK_DOMAINS = 50
NUM_REWARD_DOMAINS = 50
NUM_DEVICES_DOMAINS = 300
NUM_DEVICE_IDENTIFIER_DOMAINS = 100
NUM_GAME_STATE_DOMAINS = 300
NUM_GAME_STATE_MAPPING_DOMAINS = 10
NUM_PUBLISHER_USER_DOMAINS = 50

mail_chimp = YAML::load_file("#{Rails.root}/config/mail_chimp.yaml")['production']
MAIL_CHIMP_API_KEY = mail_chimp['api_key']
MAIL_CHIMP_PARTNERS_LIST_ID = mail_chimp['partners_list_id']
MAIL_CHIMP_SETTINGS_KEY = mail_chimp['settings_key']
MAIL_CHIMP_WEBHOOK_KEY = mail_chimp['webhook_key']

sendgrid = YAML::load_file("#{Rails.root}/config/sendgrid.yaml")['production']
SENDGRID_USER = sendgrid['user']
SENDGRID_PASSWD = sendgrid['passwd']

SYMMETRIC_CRYPTO_SECRET = 'YI,B&nZVZQtl*YRDYpEjVE&\U\#jL2!H#H&*2d'
ICON_HASH_SALT = 'Gi97taauc9VFnb1vDbxWE1ID8Jjv06Il0EehMIKQ'
UDID_SALT = 'Z*Xac$dum8xeB9-Quv3St@RET6E6UT'

FRESHBOOKS_API_URL = 'tapjoy.freshbooks.com'
FRESHBOOKS_AUTH_TOKEN = '26c1ce82ad1cfab698746e532361f814'

PAPAYA_API_URL = 'https://papayamobile.com'
PAPAYA_SECRET = 'RT4oNOKx0QK2nJ51'

CLEAR_MEMCACHE = false

twitter = YAML::load_file("#{RAILS_ROOT}/config/twitter.yaml")
ENV['CONSUMER_KEY'] = twitter['production']['consumer_key']
ENV['CONSUMER_SECRET'] = twitter['production']['consumer_secret']

DEVICE_LINK_TRACKING_PIXEL = 'http://tapjoy.go2cloud.org/SL2P'

Sass::Plugin.options[:style] = :compressed

TAPJOY_GAMES_INVITATION_OFFER_ID = '114d3e0c-c8f3-4f42-b016-2b2f81723cd8'
TRACKING_OFFER_CURRENCY_ID = '2fa3e3cc-9376-470b-b3f1-b6f5a6369d70'
