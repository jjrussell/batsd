#!/usr/bin/env ruby

pid = `/home/webuser/tapjoyserver/server/unicorn_master_pid.rb`

if pid == ''
  server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
  env = server_type == 'test' ? 'staging' : 'production'
  `unicorn_rails -E #{env} -c /home/webuser/tapjoyserver/tapjoyads/config/unicorn.rb -D`
else
  `kill -USR2 #{pid}`
end
