##
# Imports udid's from given filename for a given app.
# Usage:
#   script/runner -e <runmode> script/import_udids.rb <app_id> <filename>

require 'logger'

logger = Logger.new('import_udids.log')

app_key = ARGV[2]
filename = ARGV[3]

app = App.new(:key => app_key)

num_udids = `wc #{filename}`.split[0]

puts "Will import #{num_udids} udids in to app: '#{app.get('name')}'"
puts "Results will be logged to import_udids.log"
print "Continue? [y/N] "
STDOUT.flush
answer = STDIN.gets
if !/^y/i.match(answer)
  exit
end

def batch_put(dal_items)
  domain_number = rand(MAX_DEVICE_APP_DOMAINS)
  lookup_items = []
  fixed_dal_items = []
  
  # Fix the domain name, so that they are all the same.
  domain_name = "device_app_list_#{domain_number}"
  dal_items.each do |item|
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
  SimpledbResource.put_items(fixed_dal_items)
  SimpledbResource.put_items(lookup_items)
  
  dal_items.clear()
end

num_new = 0
num_repeat = 0
dal_items = []

File.open(filename, "r") do |file|
  while (line = file.gets)
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
      dal.serial_save
    end
  end
  
  if (num_new + num_repeat) % 1000 == 0
    logger.info "*** Put #{num_new} new udids and #{num_repeat} repeat."
  end
end

batch_put(dal_items)

logger.info "Complete. number of new udids: #{num_new}. number of udids already in system: #{num_repeat}."
