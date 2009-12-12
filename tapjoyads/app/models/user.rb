class User < SimpledbResource
  def initialize(key, options = {})
    super 'user', key, options
  end
end