class DeviceLookup < SimpledbResource
  def initialize(key, load = true)
    super 'device_lookup', key, load
  end
end