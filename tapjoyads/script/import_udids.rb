##
# Imports udid's from given filename for a given app.
# Usage:
#   script/runner -e <runmode> script/import_udids.rb <app_id> <filename>

require 'logger'
include RightAws

logger = Logger.new('import_udids.log')

app_key = ARGV[2]
filename = ARGV[3]
num_to_skip = ARGV[4] || 0

num_to_skip = num_to_skip.to_i

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

count = 0
udid_list = []

t = Time.now

File.open(filename, "r") do |file|
  while (line = file.gets)
    count += 1
    if count < num_to_skip
      if count % 1000 == 0
        logger.info "Skipped #{count} items so far."
      end
      next
    end
    
    udid = line.strip
    #udid_list.push(udid)
    
    #SqsGen2.new.queue(QueueNames::IMPORT_UDIDS).send_message(msg)
    
    dal = DeviceAppList.new(:key => udid)
    dal.set_app_ran(app_key)
    
    if dal.is_new
      num_new += 1
    else
      num_repeat += 1
    end
    
    if (num_new + num_repeat) % 1000 == 0
      logger.info "*** Put #{num_new} new udids and #{num_repeat} repeat. #{num_new + num_repeat} total. (#{Time.now.to_f - t.to_f}s / 1000)"
      t = Time.now
    end
  end
end

logger.info "Complete. number of new udids: #{num_new}. number of udids already in system: #{num_repeat}."
