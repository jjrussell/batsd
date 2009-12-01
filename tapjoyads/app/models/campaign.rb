class Campaign < SimpledbResource
  def initialize(key, options = {})
    super 'campaign', key, options  
  end
end