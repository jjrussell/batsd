#!/usr/bin/env ruby

workers_to_kill = 4
base_dir = File.expand_path("../../", __FILE__)
pid = `#{base_dir}/server/unicorn_master_pid.rb`
hostname = `hostname`.strip
server_type = `#{base_dir}/server/server_type.rb`

# Kill off workers without a master
system('/usr/local/bin/kill_singular_workers')

if pid == ''
  env = case server_type
        when "testserver": "staging"
        when "staging"   : "development"
        when "dev"       : "development"
        else               "production"
        end
  `bundle exec unicorn -E #{env} -c #{base_dir}/tapjoyads/config/unicorn.rb -D`
else
  if server_type == "dev"
    puts "Dev environment, memory management is up to you"
  else
    # gracefully restart all current workers to free up RAM,
    #   then respawn master
    `kill -HUP #{pid}`
    `kill -USR2 #{pid}`
  end
end
