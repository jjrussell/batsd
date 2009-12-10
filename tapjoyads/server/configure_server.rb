#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

server_type = `/home/webuser/server/server_type.rb`
if server_type == 'website' || server_type == 'testwebsite'
  `rm -rf /home/webuser/tapjoyads`
  `svn co https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyrailswebsite/trunk/tapjoywebsite /home/webuser/tapjoyads`
end

puts `/home/webuser/server/deploy.rb`
  