#!/usr/bin/env ruby

# setup ssh
`cp /home/webuser/tapjoyserver/server/ssh_host_rsa_key /etc/ssh/`
`cp /home/webuser/tapjoyserver/server/ssh_host_rsa_key.pub /etc/ssh/`
`/etc/init.d/ssh restart`

server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
if server_type == 'memcached'
  `/etc/init.d/memcached start`
else
  # setup log directories
  `mkdir -p /mnt/log/apache2`
  `mkdir -p /mnt/log/rails`
  `chmod 777 /mnt/log`
  `chown -R webuser:webuser /mnt/log`
  `rm -rf /var/log/apache2`
  `rm -rf /home/webuser/tapjoyserver/tapjoyads/log`
  `ln -s /mnt/log/apache2 /var/log/apache2`
  `ln -s /mnt/log/rails /home/webuser/tapjoyserver/tapjoyads/log`

  # deploy the latest code
  if server_type == 'test'
    `su webuser -c '/home/webuser/tapjoyserver/server/deploy.rb master'`
  else
    `su webuser -c '/home/webuser/tapjoyserver/server/deploy.rb'`
  end

  # start apache
  `/etc/init.d/apache2 start`

  # boot the app
  `su webuser -c 'curl -s http://localhost:9898/healthz'`

  # install cronjob on webservers
  if server_type == 'web'
    `echo "* * * * * /home/webuser/tapjoyserver/server/ensure_apache_running.rb" | crontab -u ubuntu -`
  end
end
