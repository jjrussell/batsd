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
num_msgs = 0

t = Time.now

File.open(filename, "r") do |file|
  while (line = file.gets)
    count += 1
    if count < num_to_skip
      next
    end
    
    udid = line.strip
    udid_list.push(udid)
    
    if udid_list.length == 120
      msg = {'app_key' => app_key, 'udid_list' => udid_list}.to_json
      SqsGen2.new.queue(QueueNames::IMPORT_UDIDS).send_message(msg)
      num_msgs += 1
      udid_list.clear
    end
    
    if count % 1000 == 0
      logger.info "*** Put #{count - num_to_skip} udids to the queue, in #{num_msgs} msgs. (skipped #{num_to_skip} udids). (#{Time.now.to_f - t.to_f}s / 1000)"
      t = Time.now
    end
  end
end

msg = {'app_key' => app_key, 'udid_list' => udid_list}.to_json
SqsGen2.new.queue(QueueNames::IMPORT_UDIDS).send_message(msg)
num_msgs += 1

logger.info "Complete. Put #{count - num_to_skip} udids to the queue, in #{num_msgs} msgs. "
