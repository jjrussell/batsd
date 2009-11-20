#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

type = `server/server_type.rb`

run_mode = 'production'
if type == 'test'
  run_mode = 'test'
end

settings = YAML::load_file('/home/webuser/server/configuration.yaml')

version = ARGV.first || settings['config']['deploy_version']
puts "Deploying version: #{version}"

svn_url = "https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/deploy/#{version}/tapjoyads"
if version == 'trunk'
  svn_url = "https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/trunk/tapjoyads"
end

puts `cd /home/webuser/tapjoyads && svn switch #{svn_url}`

puts `cd /home/webuser/tapjoyads && script/restart #{run_mode}`
