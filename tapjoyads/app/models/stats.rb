class Stats < SimpledbResource

  def initialize(key, options = {})
    super 'stats', key, options
  end
  
end