#!/usr/bin/env ruby
# Returns the type of server that this server is, by looking at this server's security group.

# For now, assume this script is run from within amazon.
# hostname = `hostname`
# unless (hostname.start_with? 'ip-' or hostname.start_with? 'domU-')
#   # This is not an amazon instance.
# end


security_groups = `curl -s http://169.254.169.254/latest/meta-data/security-groups`.split("\n")
if security_groups.include? 'testserver'
  machine_type = 'test'
elsif security_groups.include? 'jobserver'
  machine_type = 'jobs'
elsif security_groups.include? 'masterjobs'
  machine_type = 'masterjobs'
else
  machine_type = 'web'
end

print machine_type
