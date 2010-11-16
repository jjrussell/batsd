#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

if `pwd` != "/home/webuser/tapjoyserver\n"
  puts "This script must be run from /home/webuser/tapjoyserver"
  exit
end

server_type = `server/server_type.rb`
current_version = YAML::load_file('server/version.yaml')['current']
deploy_version = ARGV.first || current_version

puts "Deploying version: #{deploy_version}"

system "git checkout master 2>&1"
system "git pull 2>&1"
system "git pull --tags origin master 2>&1"
system "git checkout #{deploy_version} 2>&1"

if server_type == 'jobs' || server_type == 'masterjobs'
  `cp tapjoyads/config/newrelic-jobs.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'test'
  `cp tapjoyads/config/newrelic-test.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'web'
  `cp tapjoyads/config/newrelic-web.yml tapjoyads/config/newrelic.yml`
end

puts "Stopping jobs"
`tapjoyads/script/jobs stop`
`ps aux | grep -v grep | grep jobs`.each { |line| `kill #{line.split(' ')[1]}` }

puts "Restarting apache"
`touch tapjoyads/tmp/restart.txt`

if server_type == 'jobs' || server_type == 'masterjobs'
  puts "Starting jobs"
  `tapjoyads/script/jobs start -- production`
end
