#!/usr/bin/env ruby

PIDFILE = '/home/webuser/tapjoyserver/tapjoyads/pids/unicorn.pid'

if File.exists?(PIDFILE)
  pid = `cat #{PIDFILE}`.sub("\n", '')
else
  pid = `ps aux | grep -v grep | grep 'unicorn_rails master'`.split[1] || ''
end

print pid
