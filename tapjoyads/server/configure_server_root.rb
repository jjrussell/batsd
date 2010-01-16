#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as root, and then it will call configure_server.rb.

`mkdir -p /mnt/log/httpd`
`mkdir -p /mnt/log/rails`
`chown -R webuser.webuser /mnt/log`

# Add the opendns name servers.
`echo -e "make_resolv_conf(){\n\t:\n}" > /etc/dhclient-enter-hooks`
`chmod a+x /etc/dhclient-enter-hooks`
`echo -e "nameserver 8.8.4.4\nnameserver 8.8.8.8" > /etc/resolv.conf`
`/etc/init.d/network restart`

# Remove uneeded cron jobs, which hog cpu
`rm -f /etc/cron.daily/0logwatch`
`rm -f /etc/cron.daily/makewhatis.cron`
`rm -f /etc/cron.daily/mlocate.cron`
`rm -f /etc/cron.daily/rpm`
`rm -f /etc/cron.weekly/makewhatis.cron`

`crontab -r`

# Time
# Allow the system clock to be changed. See http://ubuntuforums.org/showthread.php?t=1172252
`echo 1 > /proc/sys/xen/independent_wallclock`
# Sometimes servers don't run ntp correctly. Maybe sleeping will help?
sleep(5)
`ntpdate 0.fedora.pool.ntp.org`
`ntpd -l /mnt/log/ntpd.log`

# Rails log rotation:
`cp /home/webuser/server/rails-logrotate /etc/logrotate.d/rails`

puts `su - webuser -c /home/webuser/server/configure_server.rb`

`apachectl start`