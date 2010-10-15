# TO REMOVE - when all device_app_list domains have finished converting to devices domains

class DeviceLookup < SimpledbResource
  self.domain_name = 'device_lookup'
  
  def save(options = {})
    super({:updated_at => false}.merge(options))
  end
end