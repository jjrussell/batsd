# Rails.root/config.ru
require 'config/environment'

use Rails::Rack::LogTailer

map '/' do
  use Rails::Rack::Static
  run ActionController::Dispatcher.new
end

if Rails.env.development?
  map '/assets' do
    environment = Sprockets::Environment.new
    environment.append_path 'app/assets/javascripts'
    environment.append_path 'app/assets/stylesheets'
    run environment
  end
end
