class Error < SimpledbResource
  def initialize
    key = UUIDTools::UUID.random_create.to_s
    super 'error', key, false
  end
end