#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as root, and then it will call configure_server.rb.

`mkdir -p /mnt/log/httpd`
`mkdir -p /mnt/log/rails`
`chown -R webuser.webuser /mnt/log`

`apachectl start`

`su - webuser /home/webuser/server/configure_server.rb`