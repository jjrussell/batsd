#!/usr/bin/env ruby
# Launches memcached servers. This will be run as webuser on startup on all memcached servers.

`killall memcached`

# Get internal ip address
ifconfig = `/sbin/ifconfig`
ip_address = ifconfig.match(/inet addr:(.*?)\s/)[1]

`memcached -u webuser -d -c 2048 -m 1200 -l #{ip_address}`

# exec "/home/webuser/server/memcached_monitor.rb"
