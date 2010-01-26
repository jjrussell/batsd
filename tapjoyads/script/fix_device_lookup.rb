##
# Fixes device_lookup items that have multiple app_list's
# Usage:
#   script/runner -e <runmode> script/fix_device_lookup.rb

logger = Logger.new('fix_device_lookup.log')

num_broken = 0
num_total = 0

t = Time.now

DeviceLookup.select do |device_lookup|
  num_total += 1
  
  domain_number_array = device_lookup.get('app_list', :force_array => true)
  if domain_number_array.length > 1
    num_broken += 1
    
    device_lookup.put('app_list', domain_number_array[0], :replace => true)
    
    begin
      device_lookup.serial_save(:catch_exceptions => false)
    rescue Exception => e
      logger.info "Error saving device_lookup: #{e}"
      logger.info device_lookup.to_json
      sleep(0.25)
      retry
    end
      
    
    main_device_app_list = SimpledbResource.new({:domain_name => "device_app_list_#{domain_number_array[0]}",
        :key => device_lookup.key})
    
    for domain_number in 1..domain_number_array.length
      device_app_list = SimpledbResource.new({:domain_name => "device_app_list_#{domain_number}",
          :key => device_lookup.key})
      
      device_app_list.attributes.each do |attr_name, attr_value|
        if attr_name.starts_with? 'app.'
          main_device_app_list.put(attr_name, attr_value)
        end
      end
      device_app_list.delete_all
    end
    
    begin
      main_device_app_list.serial_save(:catch_exceptions => false)
    rescue Exception => e
      logger.info "Error saving main_device_app_list: #{e}"
      logger.info main_device_app_list.to_json
      sleep(0.25)
      retry
    end
    
  end
  
  if num_total % 100 == 0
    logger.info "#{num_broken} broken (and now fixed) out of #{num_total} (#{Time.now.to_f - t}s / 100)"
    t = Time.now
    break
  end
end