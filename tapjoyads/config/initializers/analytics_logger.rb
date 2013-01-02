AnalyticsLogger.tap do |config|
  config.amqp_url = AMQP_URL
  config.logger.level = ANALYTICS_LOGGER_LEVEL
  config.memcache_servers = CACHE_SERVERS[:analytics_logger]
end
