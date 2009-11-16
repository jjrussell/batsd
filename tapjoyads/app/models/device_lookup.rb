class DeviceLookup < SimpledbResource
  def initialize(key, load = true, memcache = true)
    super 'device_lookup', key, load, memcache
  end
  
  def save
    begin
      super false
    rescue => e
      Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
      publish :device_lookup, self.serialize
    end
  end
  
  ##
  # Stores the item key and attributes to a json string.
  def serialize
    domain_name = @domain.name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
    {:domain => domain_name, :key => @item.key, :attrs => @item.attributes.to_a}.to_json
  end
  
  ##
  # Re-creates this item from a json string.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    domain_name = json['domain']
    
    lookup = DeviceLookup.new(key)

    attributes.each do |pair|
      lookup.put(pair[0], pair[1])
    end
    
    return lookup
  end
  
end