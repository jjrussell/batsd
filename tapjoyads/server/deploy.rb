#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

server_type = `/home/webuser/server/server_type.rb`

run_mode = 'production'
if server_type == 'test' || server_type == 'testwebsite'
  run_mode = 'test'
end

settings = YAML::load_file('/home/webuser/server/configuration.yaml')

version = ARGV.first || settings['config']['deploy_version']
puts "Deploying version: #{version}"

version_part = "deploy/#{version}"
if version == 'trunk'
  version_part = 'trunk'
end
svn_url = "https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/#{version_part}/tapjoyads"
if server_type == 'website' || server_type == 'testwebsite'
  svn_url = "https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyrailswebsite/#{version_part}/tapjoywebsite"
end

puts `cd /home/webuser/tapjoyads && svn switch #{svn_url}`


if server_type == 'jobs' || server_type == 'masterjobs'
  `mv /home/webuser/tapjoyads/config/newrelic-jobs.yml /home/webuser/tapjoyads/config/newrelic.yml`
elsif server_type == 'website' || server_type == 'testwebsite'
  # Do nothing, newrelic.yml is already named correctly.
else
  `mv /home/webuser/tapjoyads/config/newrelic-web.yml /home/webuser/tapjoyads/config/newrelic.yml`
end

puts `cd /home/webuser/tapjoyads && script/restart #{run_mode}`
