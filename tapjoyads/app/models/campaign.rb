class Campaign < SimpledbResource
  def initialize(key, load = true)
    super 'campaign', key, load  
  end
end