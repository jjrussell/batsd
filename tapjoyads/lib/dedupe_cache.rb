require 'logging'

class DedupeCache < Mc

  # This cache is used by the jobs servers and is thus async.
  # These settings smooth over memcache blips but can stall
  # waiting on memcache for a bit.
  def self.reset_connection
    options = {
      :support_cas      => false,
      :prefix_key       => RUN_MODE_PREFIX,
      :auto_eject_hosts => true,
      :tcp_nodelay      => true,
      :retry_timeout    => 30,
      :server_failure_limit => 3,
      :exception_retry_limit => 4,
      :connect_timeout  => 2,
      :timeout          => 1,
      :cache_lookups    => false
    }

    @cache              = Memcached.new(CACHE_SERVERS[:dedupe], options)
  end
  self.reset_connection

end
