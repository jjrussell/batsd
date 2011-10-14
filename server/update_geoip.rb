#!/usr/bin/env ruby

if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
  exit
end

attempts = 0

loop do
  attempts += 1
  output = `/usr/bin/geoipupdate -d /home/webuser/GeoIP/ 2>&1`
  puts output
  if $?.exitstatus == 0
    `touch /home/webuser/tapjoyserver/tapjoyads/tmp/restart.txt`
    break
  elsif $?.exitstatus == 1 && output =~ /GeoIP\ Database\ up\ to\ date/
    break
  else
    if attempts > 5
      puts "Failed to update Geoip Database: too many attempts"
      break
    else
      sleep(0.5)
    end
  end
end
