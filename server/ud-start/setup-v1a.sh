#!/bin/bash
#
# Set up the server for initial chef integration
#

echo "Initializing server..."
cd /tmp
sed "/^node_name/d" /etc/chef/client.rb > /tmp/client.rb
mv /tmp/client.rb /etc/chef/client.rb
wget http://10.6.127.206:9897/validation.pem -O /etc/chef/validation.pem
wget http://tj-ops.s3-website-us-east-1.amazonaws.com/chef/base-roles-v1a.json -O /etc/chef/roles.json
chef-client -j /etc/chef/roles.json

# Since tapjoy server is handled separately, we start it here
start tapjoyserver
