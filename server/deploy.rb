#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

# This points to /<dir>/connect
base_dir = File.expand_path("../../", __FILE__)

if ENV['USER'] != 'webuser'
  puts "This script must be run by webuser."
  exit
end

Dir.chdir base_dir

if File.exists?('deploy.lock')
  puts "Deploying to this server has been locked."
  puts "Lock message: #{File.read('deploy.lock')}"
  exit
end

system "git checkout deploy"

server_type = `server/server_type.rb`
current_version = YAML::load_file('server/version.yaml')['current']
deploy_version = ARGV.first || current_version

puts "Deploying version: #{deploy_version}"

system "git pull --quiet"
system "git pull --tags origin deploy"
system "git checkout #{deploy_version}"
if deploy_version == 'master'
  system "git pull --tags origin master"
end

if server_type == 'testserver' || server_type == 'staging'
  `cp config/newrelic-test.yml config/newrelic.yml`
  `cp config/local-test.yml config/local.yml`
elsif server_type == 'connect'
  `cp config/newrelic-connect.yml config/newrelic.yml`
end

if server_type == 'connect'
  `cp -f db/webserver.sqlite db/production.sqlite`
  `chmod 444 db/production.sqlite`
  `cp config/database-webserver.yml config/database.yml`
else
  `cp config/database-default.yml config/database.yml`
end


if server_type == "dev"
  `bundle install`
else
  `bundle install --local`
end

puts "Updating GeoIPCity Data"
system "bundle exec server/update_geoip.rb"

puts "Restarting unicorn"
system "bundle exec server/start_or_reload_unicorn.rb"

