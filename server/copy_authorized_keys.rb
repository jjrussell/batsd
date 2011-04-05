#!/usr/bin/env ruby

`cp /home/webuser/tapjoyserver/server/authorized_keys /home/ubuntu/.ssh/`
`cp /home/webuser/tapjoyserver/server/authorized_keys /home/webuser/.ssh/`

`chmod 600 /home/ubuntu/.ssh/authorized_keys`
`chmod 600 /home/webuser/.ssh/authorized_keys`

`chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys`
`chown webuser:webuser /home/webuser/.ssh/authorized_keys`
