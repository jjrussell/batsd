#!/usr/bin/env ruby

# setup ssh
`cp /home/webuser/server/ssh_host_rsa_key /etc/ssh/`
`cp /home/webuser/server/ssh_host_rsa_key.pub /etc/ssh/`
`/etc/init.d/ssh restart`

# stop memcached
`/etc/init.d/memcached stop`

# setup log directories
`mkdir -p /mnt/log/apache2`
`mkdir -p /mnt/log/rails`
`chown -R webuser:webuser /mnt/log`
`rm -rf /var/log/apache2`
`ln -s /mnt/log/apache2 /var/log/apache2`
`ln -s /mnt/log/rails /home/webuser/tapjoyads/log`

# enable rails log rotation
`cp /home/webuser/server/rails-logrotate /etc/logrotate.d/rails`

# deploy the latest code
`su webuser -c '/home/webuser/server/deploy.rb'`

# start apache
`/etc/init.d/apache2 start`
