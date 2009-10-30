class Device < SimpledbResource
  include Counter
  
  def initialize(key)
    super RUN_MODE_PREFIX + 'device', key
  end
end
