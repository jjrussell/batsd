#!/usr/bin/env ruby

require 'base64'

puts "server_type: " + Base64::decode64(`curl -s http://169.254.169.254/1.0/user-data`)
puts "public_ip: " + `curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
puts "public_hostname: " + `curl -s http://169.254.169.254/latest/meta-data/public-hostname`
puts "local_ip: " + `curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
puts "local_hostname: " + `curl -s http://169.254.169.254/latest/meta-data/local-hostname`
puts "instance_id: " + `curl -s http://169.254.169.254/latest/meta-data/instance-id`
puts "reservation_id: " + `curl -s http://169.254.169.254/latest/meta-data/reservation-id`
puts "security_groups: " + `curl -s http://169.254.169.254/latest/meta-data/security-groups`
puts "availability_zone: " + `curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
puts "instance_type: " + `curl -s http://169.254.169.254/latest/meta-data/instance-type`
puts "ami_manifest_path: " + `curl -s http://169.254.169.254/latest/meta-data/ami-manifest-path`
