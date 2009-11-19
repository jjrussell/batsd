class App < SimpledbResource
  def initialize(key, load = true)
    super 'app', key, load
  end
end