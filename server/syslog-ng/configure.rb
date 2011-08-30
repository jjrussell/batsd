#!/usr/bin/env ruby

base_filename = '/home/webuser/tapjoyserver/server/syslog-ng/syslog-ng.conf-client-'
conf_files    = Dir.glob("#{base_filename}*")
choices       = []

ARGV.each do |suffix|
  filename = "#{base_filename}#{suffix}"
  if conf_files.include?(filename)
    choices << filename
  else
    puts "no such configuration: #{filename}"
    exit
  end
end

choices = conf_files if choices.empty?

`cp #{choices[rand(choices.size)]} /opt/syslog-ng/etc/syslog-ng.conf`
`/etc/init.d/syslog-ng restart`
