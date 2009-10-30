class App < SimpledbResource
  include Counter
  
  def initialize(key)
    super RUN_MODE_PREFIX + 'app', key
  end
end