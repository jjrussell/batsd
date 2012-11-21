require 'logging'

class DedupeCache < Mc
  # This cache is used by the jobs servers and is thus async.
  # These settings smooth over memcache blips but can stall
  # waiting on memcache for a bit.
  def self.reset_connection
    @cache              = Dalli::Client.new(CACHE_SERVERS[:dedupe], dalli_opts)
  end

  self.reset_connection
end
