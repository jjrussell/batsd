#!/usr/bin/env ruby

pid = `/home/webuser/tapjoyserver/server/unicorn_master_pid.rb`
hostname = `hostname`.strip

if pid == ''
  server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
  env = server_type == 'test' ? 'staging' : 'production'
  `unicorn_rails -E #{env} -c /home/webuser/tapjoyserver/tapjoyads/config/unicorn.rb -D`
else
  free_mem  = `free -m`.split("\n")[2].split[3].to_i
  count = 0
  while free_mem < 300 && count < 4
    puts "dropping worker count (##{count}) for memory issue (#{hostname})"
    `kill -TTOU #{pid}`
    sleep 1
    free_mem  = `free -m`.split("\n")[2].split[3].to_i
    count += 1
  end
  if free_mem < 300
    puts "ERROR: NOT ENOUGH MEMORY - #{hostname}"
  else
    `kill -USR2 #{pid}`
  end
end
