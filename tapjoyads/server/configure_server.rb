#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

require 'rubygems'
require 'patron'

puts `/home/webuser/server/deploy.rb`

type = Base64::decode64(`curl -s http://169.254.169.254/1.0/user-data`)

# Call the register_servers job on all machines, so that they pick up this new machine's memcache.
server_list = case
when 'testserver'
  `script/ec2servers testserver`.split("\n")
else
  `script/ec2servers mc`.split("\n")
end

server_list.each do |server|
  sess = Patron::Session.new
  sess.base_url = "#{server}:9898"
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