#!/usr/bin/env ruby

min_mem = 450
pid = `/home/webuser/tapjoyserver/server/unicorn_master_pid.rb`
hostname = `hostname`.strip

if pid == ''
  server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
  env = server_type == 'test' ? 'staging' : 'production'
  `unicorn_rails -E #{env} -c /home/webuser/tapjoyserver/tapjoyads/config/unicorn.rb -D`
else
  free_mem  = `free -m`.split("\n")[2].split[3].to_i
  count = 0
  while free_mem < min_mem && count < 4
    puts "dropping worker count (##{count}) for memory issue (#{hostname})"
    `kill -TTOU #{pid}`
    sleep 2
    free_mem  = `free -m`.split("\n")[2].split[3].to_i
    count += 1
  end
  if free_mem < min_mem
    puts "ERROR: NOT ENOUGH MEMORY - #{hostname}"
  else
    `kill -USR2 #{pid}`
  end
end
