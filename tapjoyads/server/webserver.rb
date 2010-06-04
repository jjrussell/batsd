#!/usr/bin/env ruby

# setup log directories
`mkdir -p /mnt/log/httpd`
`mkdir -p /mnt/log/rails`
`chown -R webuser:webuser /mnt/log`
`su webuser -c 'ln -s /mnt/log/rails /home/webuser/tapjoyads/log'`

# enable rails log rotation
`cp /home/webuser/server/rails-logrotate /etc/logrotate.d/rails`

# deploy the latest code
`su webuser -c '/home/webuser/server/deploy.rb'`

# start apache
`/etc/init.d/apache2 start`
