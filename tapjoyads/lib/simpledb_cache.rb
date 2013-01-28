require 'logging'

class SimpledbCache < Mc

  def self.reset_connection
    options = {
      :support_cas      => true,
      :prefix_key       => RUN_MODE_PREFIX,
      :auto_eject_hosts => false,
      :tcp_nodelay      => true,
      :retry_timeout    => 300,
      :server_failure_limit => 2,
      :exception_retry_limit => 3,
      :connect_timeout  => 1,
      :cache_lookups    => false
    }

    @cache              = Memcached.new(SDB_MEMCACHE_SERVERS, options)
  end
  self.reset_connection

end
