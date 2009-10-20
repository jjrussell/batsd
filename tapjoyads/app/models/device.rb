class Device < SimpledbResource
  include Counter
  
  def initialize(key)
    super 'device', key
  end
end
