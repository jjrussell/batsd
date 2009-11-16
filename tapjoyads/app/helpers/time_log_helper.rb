module TimeLogHelper
  
  ##
  # Performs an action and then logs the time it took to perform that action.
  def time_log(message)
    start_time = Time.now
    yield
    Rails.logger.info("#{message} (#{Time.now - start_time}s)")
  end
end