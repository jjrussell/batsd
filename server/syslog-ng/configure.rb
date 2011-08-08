#!/usr/bin/env ruby

conf_files = Dir.glob("/home/webuser/tapjoyserver/server/syslog-ng/syslog-ng.conf-client-*")
`cp #{conf_files[rand(conf_files.size)]} /etc/syslog-ng/syslog-ng.conf`
`/etc/init.d/syslog-ng restart`
