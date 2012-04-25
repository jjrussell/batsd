require 'config/environment'

use Rails::Rack::LogTailer

map '/' do
  use Rails::Rack::Static
  run ActionController::Dispatcher.new
end

if Rails.env.development?
  map '/assets' do
    run Sprockets::Tj.assets
  end
end
