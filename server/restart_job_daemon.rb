#!/usr/bin/env ruby

if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
  exit
end

server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
if server_type == 'jobs' || server_type == 'masterjobs'
  puts "Stopping jobs"
  `/home/webuser/tapjoyserver/tapjoyads/script/jobs stop`
  `ps aux | grep -v grep | grep jobs`.each { |line| `kill #{line.split(' ')[1]}` }

  puts "Starting jobs"
  `/home/webuser/tapjoyserver/tapjoyads/script/jobs start -- production`
end
