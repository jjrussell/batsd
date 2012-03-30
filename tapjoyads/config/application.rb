require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

MACHINE_TYPE = `"#{Rails.root}/../server/server_type.rb"`

module Tapjoyad
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib')]

    config.encoding = 'utf-8'

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

    config.generators do |g|
      g.test_framework :rspec
    end
  end

end
