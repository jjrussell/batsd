class DeviceAppList < SimpledbResource
  def initialize(key, domain = nil, load = true, memcache = true)
    
    ##
    # If no domain is provided then we need to lookup the domain_number for this device
    unless domain
      ##
      # First look in simpledb/memcached for the app_list lookup
      lookup = DeviceLookup.new(key)
      domain_number = lookup.get('app_list') unless domain_number

      if domain_number.nil?
        ##
        # This is a new device, so add it to the next table
        domain_number = NEXT_DEVICE_APP_LIST_TABLE
        lookup.put('app_list', domain_number)
        lookup.save
      end
      
      domain = "device_app_list_#{domain_number}"   
    end

    super domain, key, load, memcache  
  end
  
  ##
  # Add an application to this device
  def add_app(app_id)
    begin
      put(app_id,  Time.now.utc.to_f.to_s)
      save
    rescue => e
      Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
      publish :add_app_to_device, serialize(app_id)
    end
  end

  ##
  # Stores the item key and app_id to a json string.
  def serialize(app_id)
    domain_name = @domain.name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
    {:domain => domain_name, :key => @item.key, :app_id => app_id }
  end
  
  ##
  # Re-creates the necessary information to add an app from the json
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    app_id = json['app_id']
    domain_name = json['domain']
    
    device_app_list = DeviceAppList.new(key, domain)

    device_app_list.put(app_id,  Time.now.utc.to_f.to_s)
    
    return device_app_list
  end
  
end