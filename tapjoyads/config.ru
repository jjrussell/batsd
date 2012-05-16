<<<<<<< HEAD
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Tapjoyad::Application
=======
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
>>>>>>> master
