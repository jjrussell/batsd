class PublisherUserRecord < SimpledbResource
  def initialize(key, load = true)
    super 'publisher-user-record', key, load  
  end
end