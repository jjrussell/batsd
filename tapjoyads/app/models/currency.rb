class Currency < SimpledbResource
  def initialize(key, options = {})
    super 'currency', key, options
  end
end