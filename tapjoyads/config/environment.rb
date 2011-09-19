# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Silence missing spec warnings - specifically for geoip gem.
Rails::VendorGemSourceIndex.silence_spec_warnings = true

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  config.frameworks -= [ :active_resource, :actionmailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)

  # These gems can't be vendored
  config.gem 'aws-sdk', :version => '1.1.2'
  config.gem 'daemons', :version => '1.0.10'
  config.gem 'hpricot', :version => '0.8.1'
  config.gem 'httparty', :version => '0.7.8'
  config.gem 'json', :version => '1.5.3'
  config.gem 'libxml-ruby', :version => '1.1.3', :lib => 'xml'
  config.gem 'memcached', :version => '1.2.7'
  config.gem 'mysql', :version => '2.8.1'
  config.gem 'nokogiri', :version => '1.5.0'
  config.gem 'patron', :version => '0.4.4'
  config.gem 'right_aws', :version => '1.10.0'
  config.gem 'rmagick', :version => '2.12.2', :lib => 'RMagick'
  config.gem 'sqlite3', :version => '1.3.3'
  config.gem 'typhoeus', :version => '0.2.0'

  # These gems should be vendored
  config.gem 'airbrake', :version => '3.0.4'
  config.gem 'authlogic', :version => '2.1.3'
  config.gem 'declarative_authorization', :version => '0.4.1'
  config.gem 'geoip', :version => '1.1.1'
  config.gem 'haml', :version => '3.1.3'
  config.gem 'plist', :version => '3.1.0'
  config.gem 'read_from_slave', :version => '0.4.0'
  config.gem 'uuidtools', :version => '2.1.2'
  config.gem 'will_paginate', :version => '2.3.12'
  config.gem 'hominid', :version => '2.2.0'
  config.gem 'curbit', :version => '0.2.0'
  config.gem 'newrelic_rpm', :version => '3.0.1'
  config.gem 'differ', :version => '0.1.2'
  config.gem 'syslog-logger', :version => '1.6.4', :lib => 'syslog_logger'
  config.gem 'vertica', :version => '0.8.1'

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :en

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_tapjoyads_session',
    :secret      => 'd3d936761e9ec0ff1aa0ce15efa6c5c6a6d0d529cfebf302de850328d321978b4d3017e36811a7bdee90ea38120346bccde1316f41849a8022a275c8390a69f1'
  }

  # Disable the IP spoofing check because a lot of cell phone proxies don't set up HTTP headers correctly.
  # http://guides.rubyonrails.org/2_3_release_notes.html#other-action-controller-changes
  config.action_controller.ip_spoofing_check = false

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  
 
  # Memcached clone instance on passenger fork:
  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Mc.reset_connection
        SimpledbResource.reset_connection
        Sqs.reset_connection
      end
    end
  end
  
  # Mailer:
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  
end

# Register custom Mime types to generate ActionOffer header files
Mime::Type.register "text/objective-c-header", :h
Mime::Type.register "text/java", :java
Mime::Type.register "application/x-apple-aspen-config", :mobileconfig
Differ.format = :html
