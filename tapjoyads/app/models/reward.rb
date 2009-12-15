class Reward < SimpledbResource
  def initialize(key = nil, options = {})
    key = UUIDTools::UUID.random_create.to_s unless key
    super 'reward', key, options
    put('created', Time.now.utc.to_f.to_s) unless get('created')
  end
end