class Stats < SimpledbResource
  include Counter
  
  def initialize(key, load = true)
    super 'stats', key, load
  end
  
end