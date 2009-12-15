class PublisherUserRecord < SimpledbResource
  def initialize(key, options = {})
    super 'publisher-user-record', key, options  
  end
end