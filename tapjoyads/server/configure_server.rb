#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

puts `/home/webuser/server/deploy.rb`
