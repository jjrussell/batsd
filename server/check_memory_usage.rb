#!/usr/bin/env ruby

free_mem  = `free -m`.split("\n")[2].split[3].to_i
threshold = 250 + rand(250)

if free_mem < threshold
  `/home/webuser/tapjoyserver/server/start_or_reload_unicorn.rb`
  `echo '#{Time.now}' >> /mnt/log/unicorn_reloads.log`
end

exit
