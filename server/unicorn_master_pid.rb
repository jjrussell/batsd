#!/usr/bin/env ruby

PIDFILE = '/home/webuser/tapjoyserver/tapjoyads/pids/unicorn.pid'

pid = ''
if File.exists?(PIDFILE)
  pid = `cat #{PIDFILE}`.strip
  `kill -s 0 #{pid}`
  pid = '' unless $?.success?
end

print pid
