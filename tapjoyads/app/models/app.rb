class App < SimpledbResource
  include Counter
  
  def initialize(key)
    super 'app', key    
  end
end