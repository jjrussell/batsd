#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

`./kill_all.rb memcached`

puts `/home/webuser/server/deploy.rb`
  