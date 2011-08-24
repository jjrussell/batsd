#!/usr/bin/env ruby

conf_files = Dir.glob("/home/webuser/tapjoyserver/server/syslog-ng/syslog-ng.conf-client-*")
`cp #{conf_files[rand(conf_files.size)]} /opt/syslog-ng/etc/syslog-ng.conf`
`/etc/init.d/syslog-ng restart`
