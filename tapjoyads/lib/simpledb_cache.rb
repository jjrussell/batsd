require 'logging'

class SimpledbCache < Mc
  def self.reset_connection
    @cache = Dalli::Client.new(SDB_MEMCACHE_SERVERS, dalli_opts)
  end

  self.reset_connection
end
