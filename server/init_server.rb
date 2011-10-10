#!/usr/bin/env ruby

server_type = `/home/webuser/tapjoyserver/server/server_type.rb`

# setup ssh keys
`/home/webuser/tapjoyserver/server/copy_authorized_keys.rb`

# setup log directories
`mkdir -p /mnt/log/apache2`
`mkdir -p /mnt/log/rails`
`mkdir -p /mnt/tmp/rails`
`chmod 777 /mnt/log`
`chmod 777 /mnt/tmp`
`chown -R webuser:webuser /mnt/log`
`chown -R webuser:webuser /mnt/tmp`
`rm -rf /var/log/apache2`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/log`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/tmp`
`ln -s /mnt/log/apache2 /var/log/apache2`
`su webuser -c 'ln -s /mnt/log/rails /home/webuser/tapjoyserver/tapjoyads/log'`
`su webuser -c 'ln -s /mnt/tmp/rails /home/webuser/tapjoyserver/tapjoyads/tmp'`

# configure syslog-ng
`/home/webuser/tapjoyserver/server/syslog-ng/configure.rb`

# configure geoip database
`su webuser -c 'geoipupdate -d /home/webuser/GeoIP/'`
`rm -rf /home/webuser/tapjoyserver/tapjoyads/data/GeoIPCity.dat`
`su webuser -c 'ln -s /home/webuser/GeoIP/GeoIPCity.dat /home/webuser/tapjoyserver/tapjoyads/data/'`

# deploy the latest code
if server_type == 'test'
  `su webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb master'`
else
  `su webuser -c 'cd /home/webuser/tapjoyserver && server/deploy.rb'`
end

# start apache
`cp /home/webuser/tapjoyserver/server/apache2.conf /etc/apache2/`
`cp /home/webuser/tapjoyserver/server/passenger.conf /etc/apache2/mods-available/`
`cp /home/webuser/tapjoyserver/server/passenger.load /etc/apache2/mods-available/`
`/etc/init.d/apache2 start`

# start memcached and mysql on testservers
if server_type == 'test'
  `/etc/init.d/memcached start`
  `start mysql`
end

# boot the app
`su webuser -c 'curl -s http://localhost:9898/healthz'`
