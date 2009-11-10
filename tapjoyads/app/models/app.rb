class App < SimpledbResource
  include Counter
  
  def initialize(key, use_memcache = true)
    super 'app', key, use_memcache    
  end
end