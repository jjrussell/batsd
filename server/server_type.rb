#!/usr/bin/env ruby
# Returns the type of server that this server is, by looking at this server's security group.

hostname = `hostname`
unless hostname =~ /^ip-|^domU-/
  # This is not an amazon instance.
  print 'dev'
  exit
end

security_groups = `curl -s http://169.254.169.254/latest/meta-data/security-groups`.split("\n")
if security_groups.include? 'testserver'
  server_type = 'test'
elsif security_groups.include? 'jobserver'
  server_type = 'jobs'
elsif security_groups.include? 'masterjobs'
  server_type = 'masterjobs'
elsif security_groups.include? 'webserver'
  server_type = 'web'
elsif security_groups.include? 'memcached'
  server_type = 'memcached'
elsif security_groups.include? 'website'
  server_type = 'website'
end

print server_type
