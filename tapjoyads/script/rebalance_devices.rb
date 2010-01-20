#!/usr/bin/env ruby
#
# Rebalances items in device_app_list_1 to be spread accross device_app_list_[0-9]

require 'logger'

items_to_delete = []

# Deletion thread. Deletes items that have been rebalanced 15 seconds after their rebalancing.
# Thread.new do
#   logger = Logger.new('delete_thread.log')
#   loop do
#     sleep(0.1)
#     item_to_delete = items_to_delete.first
#     next unless item_to_delete
#     next unless Time.now.utc > item_to_delete[:time] + 15
#     old_device_app_list = SimpledbResource.new({:domain_name => "device_app_list_1",
#         :key => item_to_delete[:key]})
#     new_device_app_list = SimpledbResource.new({
#       :domain_name => "device_app_list_#{item_to_delete[:domain_number]}",
#       :key => item_to_delete[:key],
#       :load_from_memcache => false})
#       
#     if old_device_app_list.attributes != new_device_app_list.attributes
#       logger.info "Change in #{old_device_app_list.key}. Resaving."
#       logger.info "Old attrs: #{old_device_app_list.attributes.to_json}"
#       logger.info "New attrs: #{new_device_app_list.attributes.to_json}"
#       
#       new_device_app_list = SimpledbResource.new({
#         :domain_name => "device_app_list_#{item_to_delete[:domain_number]}",
#         :key => item_to_delete[:key],
#         :attrs_to_add => old_device_app_list.attributes})
#       new_device_app_list.save(:updated_at => false)
#     end
#     logger.info "Deleting #{old_device_app_list.key} from device_app_list_1"
#     old_device_app_list.delete_all
#     
#     items_to_delete = items_to_delete[1,items_to_delete.length]
#   end
# end

main_logger = Logger.new('rebalance_devices.log')
to_delete_logger = Logger.new('to_delete.log')

loop_count = 0
start_time = nil
where = nil

loop do
  start_time = Time.now.utc
  main_logger.info "Starting loop #{loop_count} at #{start_time}"
  #total_items = SimpledbResource.count(:domain_name => 'device_app_list_1', :where => where)
  total_items = 20000000
  main_logger.info "#{total_items} total items to rebalance this loop."
  
  num_rebalanced = 0
  num_skipped = 0
  
  device_lookup_items = []
  device_app_list_items = []
  new_domain_number = rand(MAX_DEVICE_APP_DOMAINS)
  
  SimpledbResource.select(:domain_name => 'device_app_list_1', :where => where) do |device_app_list|
    device_lookup = DeviceLookup.new(:key => device_app_list.key)
    unless device_lookup.attributes.empty?
      num_skipped += 1
      if num_skipped % 10000 == 0
        main_logger.info "#{num_skipped} skipped"
      end
      next
    end
    
    if new_domain_number != 1
      new_device_app_list = SimpledbResource.new({:domain_name => "device_app_list_#{new_domain_number}",
          :key => device_app_list.key, :attrs_to_add => device_app_list.attributes, :load => false,
          :attributes => device_app_list.attributes})
      device_app_list_items.push(new_device_app_list)
      
      to_delete_logger.info device_app_list.key
      #items_to_delete.push({:time => Time.now.utc, :key => device_app_list.key, 
      #    :domain_number => new_domain_number})
    end
    
    device_lookup.put('app_list', new_domain_number)
    device_lookup_items.push(device_lookup)
    
    if device_app_list_items.length == 25
      device_app_list_items.each do |item|
        item.save(:updated_at => false, :write_to_sdb => false)
      end
      
      SimpledbResource.put_items(device_app_list_items)
      domain_name = device_app_list_items[0].this_domain_name
      main_logger.info "Wrote 25 device_app_lists to #{domain_name}"
      device_app_list_items.clear
    end

    if device_lookup_items.length == 25
      device_lookup_items.each do |item|
        item.save(:updated_at => false, :write_to_sdb => false)
      end
      
      SimpledbResource.put_items(device_lookup_items)
      main_logger.info "Wrote 25 device_lookups with value #{new_domain_number}"
      device_lookup_items.clear
      new_domain_number = rand(MAX_DEVICE_APP_DOMAINS)
    end
    
    num_rebalanced += 1
    
    if num_rebalanced % 100 == 0
      main_logger.info "#{num_rebalanced} rebalanced out of approx. #{total_items} (with #{num_skipped} skipped)"
    end
  end
  
  main_logger.info "Loop #{loop_count} complete in #{Time.now - start_time}s"
  main_logger.info "num_rebalanced: #{num_rebalanced}, num_skipped: #{num_skipped}"
  loop_count += 1
  sleep(15)
  
  where = "`updated-at` > '#{start_time.to_f}'"
end