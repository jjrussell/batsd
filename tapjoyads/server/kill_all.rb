#!/usr/bin/env ruby

ps_output = `ps aux | grep #{ARGV.first}`
ps_output.each do |line|
  pid = line.split(' ')[1]
  
  `kill #{pid}` unless pid.to_i == Process.pid
end


