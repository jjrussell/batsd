#!/usr/bin/env ruby

base_dir = File.expand_path("../../", __FILE__)
pidfiles = Dir.glob("#{base_dir}/tapjoyads/pids/*.pid")

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
