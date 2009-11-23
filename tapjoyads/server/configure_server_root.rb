#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as root, and then it will call configure_server.rb.

`mkdir -p /mnt/log/httpd`
`mkdir -p /mnt/log/rails`
`chown -R webuser.webuser /mnt/log`

# Add the opendns name servers.
`echo -e "make_resolv_conf(){\n\t:\n}" > /etc/dhclient-enter-hooks`
`chmod a+x /etc/dhclient-enter-hooks`
`echo "nameserver 208.67.222.222" >> /etc/resolv.conf`
`echo "nameserver 208.67.220.220" >> /etc/resolv.conf`
`/etc/init.d/network restart`

# Remove uneeded cron jobs, which hog cpu
`rm -f /etc/cron.daily/0logwatch`
`rm -f /etc/cron.daily/makewhatis.cron`
`rm -f /etc/cron.daily/mlocate.cron`
`rm -f /etc/cron.daily/rpm`
`rm -f /etc/cron.weekly/makewhatis.cron`

`crontab -r`

# Rails log rotation:
`cp /home/webuser/server /etc/logrotate.d/rails`

`apachectl start`

puts `su - webuser -c /home/webuser/server/configure_server.rb`