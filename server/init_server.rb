#!/usr/bin/env ruby

base_dir = File.expand_path("../../", __FILE__)

server_type = `su - webuser -c '#{File.join(base_dir,"server","server_type.rb")}'`

# testserver-specific config
if %( testserver staging ).include?(server_type)
  `rm -f /home/webuser/.tapjoy_aws_credentials.yaml`
  `/etc/init.d/memcached start`
  `start mysql`
end

# setup log directories
`chmod 777 /mnt/log`
`chmod 777 /mnt/tmp`
`chown -R webuser:webuser /mnt/log`
`chown -R webuser:webuser /mnt/tmp`
`mkdir -p /mnt/log/nginx`
`mkdir -p /mnt/log/unicorn`
`mkdir -p /mnt/log/rails`
`mkdir -p /mnt/tmp/rails`
`rm -rf /var/log/nginx`
`rm -rf #{base_dir}/log`
`rm -rf #{base_dir}/tmp`
`ln -s /mnt/log/nginx /var/log/nginx`
`su - webuser -c 'ln -s /mnt/log/rails #{base_dir}/log'`
`su - webuser -c 'ln -s /mnt/tmp/rails #{base_dir}/tmp'`

# configure geoip database
`su - webuser -c '#{base_dir}/server/update_geoip.rb'`
`rm -rf #{base_dir}/data/GeoIPCity.dat`
`su - webuser -c 'ln -s /home/webuser/GeoIP/GeoIPCity.dat #{base_dir}/data/'`

# deploy the latest code
if %w( testserver staging util ).include?(server_type)
  `su - webuser -c 'cd #{base_dir} && server/deploy.rb master'`
else
  `su - webuser -c 'cd #{base_dir} && server/deploy.rb'`
end

# start nginx
`/etc/init.d/nginx start`
