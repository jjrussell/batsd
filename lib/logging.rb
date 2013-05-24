def log_info_with_time(message)
  start_time = Time.zone.now
  yield if block_given?
  message += " (#{Time.zone.now - start_time})"
  Rails.logger.info message
end
