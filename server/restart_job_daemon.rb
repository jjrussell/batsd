#!/usr/bin/env ruby

base_dir = File.expand_path("../..", __FILE__)

if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
  exit
end

server_type = `#{base_dir}/server/server_type.rb`
if server_type == 'jobserver' || server_type == 'queues-nodb'
  puts "Stopping jobs"
  `#{base_dir}/script/jobs stop`
  `ps aux | grep -v grep | grep jobs`.each { |line| `kill -9 #{line.split(' ')[1]}` }

  puts "Starting jobs"
  `#{base_dir}/script/jobs start -- production`
end
