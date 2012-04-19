#!/usr/bin/env ruby
# Returns the type of server that this server is, by looking at this server's security group.

hostname = `hostname`
unless hostname =~ /^ip-|^domU-/
  # This is not an amazon instance.
  print 'dev'
  exit
end

print `curl -s http://169.254.169.254/latest/meta-data/security-groups`.split("\n").reject {|g| g == "tapbase"}.first
