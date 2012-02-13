#!/usr/bin/env ruby

pidfiles = Dir.glob("/home/webuser/tapjoyserver/tapjoyads/pids/*.pid")

pid = ''
pidfiles.each do |pidfile|
  p = `cat #{pidfile}`.strip
  `kill -s 0 #{p} 2> /dev/null`
  if $?.success?
    pid << "#{p} "
  else
    File.delete(pidfile)
  end
end

print pid.strip
