AnalyticsLogger.amqp_url = AMQP_URL
AnalyticsLogger.redis_url = ANALYTICS_REDIS_URL
AnalyticsLogger.syslogger = SyslogLogger.new("#{RUN_MODE_PREFIX}rails-web_requests")
