#!/bin/sh

# setup ssh
cp /home/webuser/server/init/ssh_host_rsa_key /etc/ssh/
cp /home/webuser/server/init/ssh_host_rsa_key.pub /etc/ssh/
/etc/init.d/ssh restart

# kill the motd
rm /etc/cron.d/cloudinit-updates
rm /etc/motd

# start god/memcached
/usr/bin/god -c /home/webuser/server/god/memcached.god
