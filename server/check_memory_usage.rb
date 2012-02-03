#!/usr/bin/env ruby

free_mem  = `free -m`.split("\n")[2].split[3].to_i
threshold = 250 + rand(250)

if free_mem < threshold
  pid = `/home/webuser/tapjoyserver/server/unicorn_master_pid.rb`
  `kill -USR2 #{pid}`
  `echo '#{Time.now}' >> /mnt/log/unicorn_reloads.log`
end

exit
