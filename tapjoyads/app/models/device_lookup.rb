class DeviceLookup < SimpledbResource
  def initialize(key, options = {})
    super 'device_lookup', key, options
  end
end