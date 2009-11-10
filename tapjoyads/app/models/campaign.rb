class Campaign < SimpledbResource
  def initialize(key, use_memcache = true)
    super 'campaign', key, use_memcache    
  end
end