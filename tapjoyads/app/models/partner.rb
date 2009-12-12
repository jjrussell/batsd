class Partner < SimpledbResource
  def initialize(key, options = {})
    super 'partner', key, options
  end
end