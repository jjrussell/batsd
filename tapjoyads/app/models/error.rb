class Error < SimpledbResource
  def initialize(key, use_memcache = true)
    super 'error', key, use_memcache    
  end
end