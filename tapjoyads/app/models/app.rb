class App < SimpledbResource
  def initialize(key, load = true, memcache = true)
    super 'app', key, load, memcache
  end
end