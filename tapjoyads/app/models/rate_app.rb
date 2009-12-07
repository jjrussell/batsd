class RateApp < SimpledbResource
  def initialize(key, options = {})
    super 'rate_app', key, options
  end
end