#!/usr/bin/env ruby

# setup ssh
`cp /home/webuser/server/ssh_host_rsa_key /etc/ssh/`
`cp /home/webuser/server/ssh_host_rsa_key.pub /etc/ssh/`
`/etc/init.d/ssh restart`

# setup log directories
`mkdir -p /mnt/log/apache2`
`mkdir -p /mnt/log/rails`
`chmod 777 /mnt/log`
`chown -R webuser:webuser /mnt/log`
`rm -rf /var/log/apache2`
`ln -s /mnt/log/apache2 /var/log/apache2`
`ln -s /mnt/log/rails /home/webuser/tapjoyads/log`

# deploy the latest code
`su webuser -c '/home/webuser/server/deploy.rb'`

# start apache
`/etc/init.d/apache2 start`

# boot the app
`su webuser -c 'curl -s http://localhost:9898/healthz'`

# install cronjob on webservers
server_type = `/home/webuser/server/server_type.rb`
if server_type == 'web'
  `echo "* * * * * /home/webuser/server/ensure_apache_running.rb" | crontab -u ubuntu -`
end
