#!/usr/bin/env ruby

server_type = `su - webuser -c '/home/webuser/tapjoyserver/server/server_type.rb'`

# testserver-specific config
if %( testserver staging ).include?(server_type)
  `rm -f /home/webuser/.tapjoy_aws_credentials.yaml`
  `/etc/init.d/memcached start`
  `start mysql`
end

# setup log directories
`mkdir -p /mnt/log/nginx`
`mkdir -p /mnt/log/unicorn`
`mkdir -p /mnt/log/rails`
`mkdir -p /mnt/tmp/rails`
`chmod 777 /mnt/log`
`chmod 777 /mnt/tmp`
`chown -R webuser:webuser /mnt/log`
`chown -R webuser:webuser /mnt/tmp`
`rm -rf /var/log/nginx`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/log`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/tmp`
`ln -s /mnt/log/nginx /var/log/nginx`
`su - webuser -c 'ln -s /mnt/log/rails /home/webuser/tapjoyserver/tapjoyads/log'`
`su - webuser -c 'ln -s /mnt/tmp/rails /home/webuser/tapjoyserver/tapjoyads/tmp'`

# configure geoip database
`su - webuser -c '/home/webuser/tapjoyserver/server/update_geoip.rb'`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/data/GeoIPCity.dat`
`su - webuser -c 'ln -s /home/webuser/GeoIP/GeoIPCity.dat /home/webuser/tapjoyserver/tapjoyads/data/'`

# deploy the latest code
if %w( testserver staging util ).include?(server_type)
  `su - webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb master'`
else
  `su - webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb'`
end

# start nginx
`/etc/init.d/nginx start`
