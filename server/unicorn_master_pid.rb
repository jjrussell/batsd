#!/usr/bin/env ruby

PIDFILE = Dir.glob("/home/webuser/tapjoyserver/tapjoyads/pids/*.pid").first

pid = ''
unless PIDFILE.nil?
  pid = `cat #{PIDFILE}`.strip
  `kill -s 0 #{pid}`
  pid = '' unless $?.success?
end

print pid
