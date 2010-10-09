#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

server_type = `/home/webuser/server/server_type.rb`

run_mode = 'production'
if server_type == 'test'
  run_mode = 'test'
end

settings = YAML::load_file('/home/webuser/server/configuration.yaml')

yaml_version = settings['config']['api_deploy_version']

version = ARGV.first || yaml_version
puts "Deploying version: #{version}"

version_part = "deploy/#{version}"
if version == 'trunk'
  version_part = 'trunk'
end
svn_url = "https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/#{version_part}/tapjoyads"

puts `cd /home/webuser/tapjoyads && svn switch #{svn_url}`

if server_type == 'jobs' || server_type == 'masterjobs'
  `mv /home/webuser/tapjoyads/config/newrelic-jobs.yml /home/webuser/tapjoyads/config/newrelic.yml`
elsif server_type == 'test'
  `mv /home/webuser/tapjoyads/config/newrelic-test.yml /home/webuser/tapjoyads/config/newrelic.yml`
end

puts `cd /home/webuser/tapjoyads && script/restart #{run_mode}`
