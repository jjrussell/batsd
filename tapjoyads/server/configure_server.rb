#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

require 'rubygems'
require 'patron'

`memcached -d -m 256`

puts `/home/webuser/server/deploy.rb`

# Call the register_servers job on all machines, so that they pick up this new machine's memcache.
port = '9898'
server_list = case rails_mode
when 'production'
  `script/ec2servers mc`.split("\n")
when 'test'
  `script/ec2servers testserver`.split("\n")
else
  port = '3000'
  ['localhost:3000']
end

server_list.each do |server|
  sess = Patron::Session.new
  sess.base_url = "#{server}:#{port}"
  sess.timeout = 30
  sess.username = 'internal'
  sess.password = 'r3sU0oQav2Nl'
  sess.auth_type = :digest

  begin
    sess.get("/job/register_servers")
  rescue Patron::TimeoutError
    puts "Timed out when registering #{server}"
  end
end