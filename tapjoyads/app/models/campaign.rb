class Campaign < SimpledbResource
  def initialize(key, load = true, memcache = true)
    super 'campaign', key, load, memcache  
  end
end