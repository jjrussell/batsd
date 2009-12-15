class Reward < SimpledbResource
  def initialize(key = nil, options = {})
    key = UUIDTools::UUID.random_create.to_s unless key
    super 'reward', key, options
  end
end