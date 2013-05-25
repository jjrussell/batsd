#!/usr/bin/env ruby

min_mem = 1000
workers_to_kill = 4
base_dir = File.expand_path("../../", __FILE__)
pid = `#{base_dir}/server/unicorn_master_pid.rb`
hostname = `hostname`.strip
server_type = `#{base_dir}/server/server_type.rb`

# Kill off workers without a master
`/usr/local/bin/kill_singular_workers`

if pid == ''
  env = case server_type
        when "testserver" then "staging"
        when "staging"    then "development"
        when "dev"        then "development"
        else                   "production"
        end
  `bundle exec rainbows -E #{env} -c #{base_dir}/config/unicorn.rb -D`
else
  if server_type == "dev"
    puts "Dev environment, memory management is up to you"
    free_mem = min_mem
  else
    free_mem = `free -m`.split("\n")[2].split[3].to_i
  end
  count = 0
  while free_mem < min_mem && count < workers_to_kill
    puts "dropping worker count (##{count}) for memory issue (#{hostname})"
    `kill -TTOU #{pid}`
    sleep 2
    free_mem  = `free -m`.split("\n")[2].split[3].to_i
    count += 1
  end
  if free_mem < min_mem
    puts "ERROR: NOT ENOUGH MEMORY - #{hostname}"
  else
    # gracefully restart all current workers to free up RAM,
    #   then respawn master
    `kill -HUP #{pid}`
    `kill -USR2 #{pid}`
  end
end
