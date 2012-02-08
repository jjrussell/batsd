#!/usr/bin/env ruby

if ENV['PWD'] != '/home/webuser/tapjoyserver'
  puts "This script must be run from /home/webuser/tapjoyserver"
  exit
end
if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
  exit
end

server_type = `server/server_type.rb`
if server_type == 'jobs' || server_type == 'masterjobs'
  puts "Stopping jobs"
  `tapjoyads/script/jobs stop`
  `ps aux | grep -v grep | grep jobs`.each { |line| `kill #{line.split(' ')[1]}` }

  puts "Starting jobs"
  `tapjoyads/script/jobs start -- production`
end
