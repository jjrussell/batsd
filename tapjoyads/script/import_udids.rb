##
# Imports udid's from given filename for a given app.
# Usage:
#   script/runner -e <runmode> script/import_udids.rb <app_id> <filename>

require 'logger'

logger = Logger.new('import_udids.log')

app_key = ARGV[2]
filename = ARGV[3]
num_to_skip = ARGV[4] || 0

app = App.new(:key => app_key)

num_udids = `wc #{filename}`.split[0]

puts "Will import #{num_udids} udids in to app: '#{app.get('name')}'"
puts "Skip the first #{num_to_skip} udids."
puts "Results will be logged to import_udids.log"
print "Continue? [y/N] "
STDOUT.flush
answer = STDIN.gets
if !/^y/i.match(answer)
  exit
end

def batch_put(dal_items)
  
  Thread.new(dal_items) do |items|
    batch_put_logger = Logger.new('import_udids_batch_puts.log')
    
    domain_number = rand(MAX_DEVICE_APP_DOMAINS)
    lookup_items = []
    fixed_dal_items = []
  
    # Fix the domain name, so that they are all the same.
    domain_name = "device_app_list_#{domain_number}"
    items.each do |item|
      fixed_dal_item = DeviceAppList.new({
        :domain_name => domain_name,
        :key => item.key,
        :attributes => item.attributes,
        :attrs_to_replace => item.attributes,
        :load => false
      })
      fixed_dal_items.push(fixed_dal_item)
    
    
      lookup = DeviceLookup.new(:key => item.key)
      lookup.put('app_list', domain_number)
      lookup_items.push(lookup)
    end
  
    # Write to memcache.
    fixed_dal_items.each do |item|
      item.is_new = false
      item.save(:write_to_sdb => false)
    end
    lookup_items.each do |item|
      item.save(:write_to_sdb => false)
    end
  
    # Now batch_put the items to sdb
    begin
      SimpledbResource.put_items(fixed_dal_items)
    rescue Exception => e
      batch_put_logger.info "Error batch_putting domain_app_list: #{e}"
      batch_put_logger.info fixed_dal_items.to_json
      sleep(1)
      retry
    end
    
    begin
      SimpledbResource.put_items(lookup_items)
    rescue Exception => e
      batch_put_logger.info "Error batch_putting lookup_items: #{e}"
      batch_put_logger.info lookup_items.to_json
      sleep(1)
      retry
    end
    
    batch_put_logger.info "Successfully wrote 25 items to domain #{domain_number}"
  end
  
  dal_items.clear()
end

num_new = 0
num_repeat = 0
count = 0
dal_items = []

t = Time.now

File.open(filename, "r") do |file|
  while (line = file.gets)
    count += 1
    if count < num_to_skip
      next
    end
    
    udid = line.strip
    dal = DeviceAppList.new(:key => udid)
    dal.set_app_ran(app_key)
    
    if dal.is_new
      num_new += 1
      dal_items.push(dal)
      if dal_items.length == 25
        batch_put(dal_items)
      end
    else
      num_repeat += 1
      dal.save
    end
    
    if num_repeat % 100 == 0
      # Sleep every 100 num_repeats, so that the save threads get a chance to catch up.
      sleep(0.5)
    end
    
    if num_new % 250 == 0
      sleep(1)
    end
    
    if (num_new + num_repeat) % 1000 == 0
      logger.info "*** Put #{num_new} new udids and #{num_repeat} repeat. #{num_new + num_repeat} total. (#{Time.now - t.to_f}s / 1000)"
      t = Time.now
    end
  end
end

batch_put(dal_items)

logger.info "Complete. number of new udids: #{num_new}. number of udids already in system: #{num_repeat}."
