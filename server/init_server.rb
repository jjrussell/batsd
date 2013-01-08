#!/usr/bin/env ruby

server_type = `su - webuser -c '/home/webuser/connect/server/server_type.rb'`

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
`rm -rf /home/webuser/connect/tapjoyads/log`
`rm -rf /home/webuser/connect/tapjoyads/tmp`
`ln -s /mnt/log/nginx /var/log/nginx`
`su - webuser -c 'ln -s /mnt/log/rails /home/webuser/connect/tapjoyads/log'`
`su - webuser -c 'ln -s /mnt/tmp/rails /home/webuser/connect/tapjoyads/tmp'`

# configure geoip database
`su - webuser -c '/home/webuser/connect/server/update_geoip.rb'`
`rm -rf /home/webuser/connect/tapjoyads/data/GeoIPCity.dat`
`su - webuser -c 'ln -s /home/webuser/GeoIP/GeoIPCity.dat /home/webuser/connect/tapjoyads/data/'`

# deploy the latest code
if %w( testserver staging util ).include?(server_type)
  `su - webuser -c 'cd /home/webuser/connect && server/deploy.rb master'`
else
  `su - webuser -c 'cd /home/webuser/connect && server/deploy.rb'`
end

# start nginx
`/etc/init.d/nginx start`
