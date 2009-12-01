class App < SimpledbResource
  def initialize(key, options = {})
    super 'app', key, options
  end
end