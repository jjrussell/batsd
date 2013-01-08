#!/usr/bin/env ruby
# Returns the type of server that this server is.

hostname = `hostname`
if hostname =~ /^ip-|^domU-/
  print 'connect'
else
  # This is not an amazon instance.
  print 'dev'
  exit
end
