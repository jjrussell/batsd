class ReceivedOffer < SimpledbResource
  def initialize(key, options = {})
    super 'received_offer', key, options
  end
end