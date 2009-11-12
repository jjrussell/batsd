class Error < SimpledbResource
  def initialize
    key = UUID.generate
    super 'error', key, false
  end
end