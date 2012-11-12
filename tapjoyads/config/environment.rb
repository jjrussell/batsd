# Load the rails application
require File.expand_path('../application', __FILE__)

# Redirect logs to console
if defined?(Rails::Console) && ENV['DISABLE_CONSOLE_LOGGING'] != 'false'
  Rails.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end

# Initialize the rails application
Tapjoyad::Application.initialize!
