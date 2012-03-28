# Rails.root/config.ru
if Rails.env.development?
  require 'config/environment'

  use Rails::Rack::LogTailer

  map '/' do
    use Rails::Rack::Static
    run ActionController::Dispatcher.new
  end

  map '/assets' do
    environment = Sprockets::Environment.new
    environment.append_path 'app/assets/javascripts'
    environment.append_path 'app/assets/stylesheets'
    run environment
  end
end
