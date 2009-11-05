class Stats < SimpledbResource
  include Counter
  
  def initialize(key)
    super 'stats', key
  end
  
end