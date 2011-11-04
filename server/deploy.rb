#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

if ENV['PWD'] != '/home/webuser/tapjoyserver'
  puts "This script must be run from /home/webuser/tapjoyserver"
  exit
end
if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
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
  `cp tapjoyads/config/local-test.yml tapjoyads/config/local.yml`
elsif server_type == 'web'
  `cp tapjoyads/config/newrelic-web.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'website'
  `cp tapjoyads/config/newrelic-website.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'dashboard'
  `cp tapjoyads/config/newrelic-dashboard.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'util'
  `cp tapjoyads/config/newrelic-util.yml tapjoyads/config/newrelic.yml`
  `cp tapjoyads/config/local-util.yml tapjoyads/config/local.yml`
end

if server_type == 'web'
  `cp -f tapjoyads/db/webserver.sqlite tapjoyads/db/production.sqlite`
  `chmod 444 tapjoyads/db/production.sqlite`
  `cp tapjoyads/config/database-webserver.yml tapjoyads/config/database.yml`
else
  `cp tapjoyads/config/database-default.yml tapjoyads/config/database.yml`
end

if server_type == 'jobs' || server_type == 'masterjobs'
  puts "Stopping jobs"
  `tapjoyads/script/jobs stop`
  `ps aux | grep -v grep | grep jobs`.each { |line| `kill #{line.split(' ')[1]}` }

  puts "Starting jobs"
  `tapjoyads/script/jobs start -- production`
end

puts "Restarting passenger"
`touch tapjoyads/tmp/restart.txt`
