require 'logging'

class StatsCache < MemcachedMc
  def self.reset_connection
    @cache = Memcached.new(CACHE_SERVERS[:stats], {
      :prefix_key => RUN_MODE_PREFIX,
      :auto_eject_hosts => false,
      :tcp_nodelay => true,
      :retry_timeout => 300,
      :server_failure_limit => 2,
      :exception_retry_limit => 2,
      :connect_timeout => 1,
      :cache_lookups => false
    })
  end

  self.reset_connection
end
