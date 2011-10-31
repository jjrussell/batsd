#!/usr/bin/env ruby

server_type = `su - webuser -c '/home/webuser/tapjoyserver/server/server_type.rb'`

if server_type == 'test'
  `cp /home/webuser/tapjoyserver/server/authorized_keys-dev /home/ubuntu/.ssh/authorized_keys`
  `cp /home/webuser/tapjoyserver/server/authorized_keys-dev /home/webuser/.ssh/authorized_keys`
else
  `cp /home/webuser/tapjoyserver/server/authorized_keys-ops /home/ubuntu/.ssh/authorized_keys`
  `cp /home/webuser/tapjoyserver/server/authorized_keys-ops /home/webuser/.ssh/authorized_keys`
end

`chmod 600 /home/ubuntu/.ssh/authorized_keys`
`chmod 600 /home/webuser/.ssh/authorized_keys`

`chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys`
`chown webuser:webuser /home/webuser/.ssh/authorized_keys`
