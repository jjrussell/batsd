AnalyticsLogger.tap do |config|
  config.amqp_url = AMQP_URL
  config.amqp_namespace = 'events.test'
  config.mirror_to_syslog = true
  config.syslog_name = "#{RUN_MODE_PREFIX}rails-web_requests"
end