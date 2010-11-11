#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

`cd /home/webuser/tapjoyserver`

system "git checkout master"
system "git pull --tags origin master"

server_type = `server/server_type.rb`
current_version = YAML::load_file('server/version.yaml')['current']
deploy_version = ARGV.first || current_version

puts "Deploying version: #{deploy_version}"

system "git checkout #{deploy_version}"

`cd tapjoyads`

if server_type == 'jobs' || server_type == 'masterjobs'
  `cp config/newrelic-jobs.yml config/newrelic.yml`
elsif server_type == 'test'
  `cp config/newrelic-test.yml config/newrelic.yml`
elsif server_type == 'web'
  `cp config/newrelic-web.yml config/newrelic.yml`
end

puts "Stopping jobs"
`script/jobs stop`
`ps aux | grep -v grep | grep jobs`.each { |line| `kill #{line.split(' ')[1]}` }

puts "Restarting apache"
`touch tmp/restart.txt`

if server_type == 'jobs' || server_type == 'masterjobs'
  puts "Starting jobs"
  `script/jobs start -- production`
end
