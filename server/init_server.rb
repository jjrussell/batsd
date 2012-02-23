#!/usr/bin/env ruby

server_type = `su - webuser -c '/home/webuser/tapjoyserver/server/server_type.rb'`

# testserver-specific config
if server_type == 'test'
  `rm -f /home/webuser/.tapjoy_aws_credentials.yaml`
  `/etc/init.d/memcached start`
  `start mysql`
end

# setup ssh keys
`/home/webuser/tapjoyserver/server/copy_authorized_keys.rb`

# Fix the limits stuff
`cp /home/webuser/tapjoyserver/server/limits.conf /etc/security/limits.conf`
`cp /home/webuser/tapjoyserver/server/common-session /etc/pam.d/common-session`

# setup log directories
`mkdir -p /mnt/log/apache2`
`mkdir -p /mnt/log/nginx`
`mkdir -p /mnt/log/unicorn`
`mkdir -p /mnt/log/rails`
`mkdir -p /mnt/tmp/rails`
`chmod 777 /mnt/log`
`chmod 777 /mnt/tmp`
`chown -R webuser:webuser /mnt/log`
`chown -R webuser:webuser /mnt/tmp`
`rm -rf /var/log/apache2`
`rm -rf /var/log/nginx`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/log`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/tmp`
`ln -s /mnt/log/apache2 /var/log/apache2`
`ln -s /mnt/log/nginx /var/log/nginx`
`su - webuser -c 'ln -s /mnt/log/rails /home/webuser/tapjoyserver/tapjoyads/log'`
`su - webuser -c 'ln -s /mnt/tmp/rails /home/webuser/tapjoyserver/tapjoyads/tmp'`
`su - webuser -c 'mkdir /home/webuser/tapjoyserver/tapjoyads/pids'`

# configure rails log rotation
`cp /home/webuser/tapjoyserver/server/rails-logrotate /etc/logrotate.d/rails`

# configure syslog-ng
`/home/webuser/tapjoyserver/server/syslog-ng/configure.rb`

# configure geoip database
`su - webuser -c '/home/webuser/tapjoyserver/server/update_geoip.rb'`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/data/GeoIPCity.dat`
`su - webuser -c 'ln -s /home/webuser/GeoIP/GeoIPCity.dat /home/webuser/tapjoyserver/tapjoyads/data/'`

# setup nginx
`cp /home/webuser/tapjoyserver/server/nginx.conf /etc/nginx/`
`cp /home/webuser/tapjoyserver/server/tapjoy-nginx /etc/nginx/sites-available/tapjoy`

# deploy the latest code
if server_type == 'test' || server_type == 'util'
  `su - webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb master'`
else
  `su - webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb'`
end

# start nginx
`/etc/init.d/nginx start`

# HACK: job to restart unicorn when memory is low
if server_type == 'web'
  `echo "* * * * * /home/webuser/tapjoyserver/server/check_memory_usage.rb" | crontab -u webuser -`
end
