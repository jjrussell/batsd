##
# Fixes device_lookup items that have multiple app_list's
# Usage:
#   script/runner -e <runmode> script/fix_device_lookup.rb

log_file = ARGV[3] || 'fix_device_lookup.log'
num_to_skip = (ARGV[4] || 0).to_i

logger = Logger.new(log_file)

num_broken = 0
num_total = 0
num_skipped = 0

if num_to_skip > 0
  sdb = RightAws::SdbInterface.new(nil, nil, {:port => 80, :protocol => 'http'})
  next_token = nil
  begin
    response = sdb.select('select count(*) from device_lookup', next_token)
    num_skipped += response[:items][0]['Domain']['Count'][0].to_i
    next_token = response[:next_token]
  end while num_skipped < num_to_skip
end

t = Time.now

DeviceLookup.select(:next_token => next_token) do |device_lookup|
  num_total += 1
  
  domain_number_array = device_lookup.get('app_list', :force_array => true)
  if domain_number_array.length > 1
    num_broken += 1
    
    device_lookup.put('app_list', domain_number_array[0], :replace => true)
    
    begin
      device_lookup.serial_save(:catch_exceptions => false, :updated_at => false)
    rescue Exception => e
      logger.info "Error saving device_lookup: #{e}"
      logger.info device_lookup.to_json
      sleep(0.25)
      retry
    end
      
    
    main_device_app_list = SimpledbResource.new({:domain_name => "device_app_list_#{domain_number_array[0]}",
        :key => device_lookup.key})
    added_apps = []
    
    for i in 1..domain_number_array.length - 1
      device_app_list = SimpledbResource.new({:domain_name => "device_app_list_#{domain_number_array[i]}",
          :key => device_lookup.key})
      
      device_app_list.attributes.each do |attr_name, attr_value|
        if attr_name.starts_with? 'app.'
          main_device_app_list.put(attr_name, attr_value)
        end
        added_apps.push(attr_name)
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
    
    logger.info "Fixed #{main_device_app_list.key}. Added #{added_apps.to_json}"
  end
  
  if num_total % 100 == 0
    logger.info "**#{num_broken} broken and now fixed out of #{num_total} (#{Time.now.to_f - t.to_f}s / 100) (#{num_to_skip} skipped)"
    t = Time.now
  end
end