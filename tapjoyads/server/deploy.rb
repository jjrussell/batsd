#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'
require 'base64'

type = Base64::decode64(`curl -s http://169.254.169.254/1.0/user-data`)
puts "Server type: #{type}"

run_mode = 'production'
if type == 'testserver'
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

puts `cd /home/webuser/tapjoyads && script/runner script/restart #{run_mode}`
