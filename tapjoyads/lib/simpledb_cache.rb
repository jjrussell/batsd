require 'logging'

class SimpledbCache < Mc

  def self.reset_connection
    options = {
      :support_cas      => true,
      :prefix_key       => RUN_MODE_PREFIX,
      :auto_eject_hosts => false,
      :cache_lookups    => false
    }

    @@cache              = Memcached.new(SDB_MEMCACHE_SERVERS, options)
  end

end
