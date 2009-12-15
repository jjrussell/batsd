class ReceivedOffer < SimpledbResource
  def initialize(key = nil, options = {})
    key = UUIDTools::UUID.random_create.to_s unless key
    super 'received_offer', key, options
  end
end