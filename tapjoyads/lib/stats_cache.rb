require 'logging'

class StatsCache < Mc
  def self.reset_connection
    @cache              = Dalli::Client.new(CACHE_SERVERS[:stats], dalli_opts)
  end
  
  self.reset_connection
end
