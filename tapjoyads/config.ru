require 'config/environment'

if Rails.env.development?
  use Rails::Rack::LogTailer

  map '/' do
    use Rails::Rack::Static
    run ActionController::Dispatcher.new
  end

  map '/assets' do
    run Sprockets::Tj.assets
  end
end
