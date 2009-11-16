#!/usr/bin/env ruby
require 'activemessaging/processor'

include ActiveMessaging::MessageSender

arr = []
count = 0
messages = 0
bad = 0

name = ARGV.first
File.open(name, "r") do |file|
  while (line = file.gets) 
    begin
      items = line.split(',')
      udid = items[0]
      app_id = items[1]
      timestamp  = Time.parse(items[2].gsub(/\s/,'T')).to_f.to_s

      set = [udid, app_id, timestamp]
      arr.push(set)
      count += 1
      if count == 50
        message = arr.to_json
        publish :process_stored_ids, message
        arr = []
        messages += 1
        print "Count: #{count}"
      end
    rescue => e
      puts 'Bad_Line: ' + line + e
      bad += 1
    end
  end
end

if arr.length > 0
  message = arr.to_json
  publish :process_stored_ids, message
  messages += 1
  arr = []
end

print "Messages sent: #{messages}"
print "Bad lines: #{bad}"
#publish :process_stored_ids, arr.serialize