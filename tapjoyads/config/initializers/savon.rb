Savon.configure do |config|
  config.log = true
  config.log_level = Rails.env.production? ? :error : :warn
  config.logger = Rails.logger unless Rails.env.development?
  config.pretty_print_xml = true
  config.raise_errors = true
end
