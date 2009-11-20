#!/usr/bin/env ruby

# A script that will run when a new ec2 instance is brought up.
# This script will run as webuser.

security_groups = `curl -s http://169.254.169.254/latest/meta-data/security-groups`.split("\n")
if security_groups.include? 'testserver'
  machine_type = :test
elsif security_groups.include? 'masterjobs'
  machine_type = :master
elsif security_groups.include? 'webserver'
  machine_type = :web
elsif security_groups.include? 'website'
  machine_type = :website
end

puts machine_type.to_s

puts `/home/webuser/server/deploy.rb`
