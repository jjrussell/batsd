require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Tapjoyad
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib')]

    config.encoding = 'utf-8'

    config.time_zone = 'UTC'
    config.i18n.default_locale = :en
    config.action_dispatch.ip_spoofing_check = false

    # Memcached clone instance on passenger fork:
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked
          Mc.reset_connection
          SimpledbResource.reset_connection
          VerticaCluster.reset_connection
        end
      end
    end

    config.action_mailer.delivery_method = :amazon_ses
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true

    config.filter_parameters = :password, :password_confirmation

    config.db_readonly_hostnames = []

    config.generators do |g|
      g.test_framework :rspec
    end

    #zero-based index of where to include a Deeplink offer in the offer list
    config.offer_list_deeplink_position = 3

    def self.route_filenames
      case MACHINE_TYPE
      when 'dashboard'
       %w( dashboard api )
      when 'website'
       %w( website api )
      when 'webserver'
       %w( web legacy )
      when 'jobserver'
       %w( job )
      else
       %w( api dashboard job website web legacy )
      end
    end
  end

end
