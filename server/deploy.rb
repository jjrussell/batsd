#!/usr/bin/env ruby

# Deploys to this server.

require 'yaml'

# This points to /<dir>/tapjoyserver
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

server_type = `server/server_type.rb`
current_version = YAML::load_file('server/version.yaml')['current']
deploy_version = ARGV.first || current_version

puts "Deploying version: #{deploy_version}"

system "git checkout master"
system "git pull --quiet"
system "git pull --tags origin master"
system "git checkout #{deploy_version}"

if server_type == 'jobserver' || server_type == 'masterjobs'
  `cp tapjoyads/config/newrelic-jobs.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'testserver' || server_type == 'staging'
  `cp tapjoyads/config/newrelic-test.yml tapjoyads/config/newrelic.yml`
  `cp tapjoyads/config/local-test.yml tapjoyads/config/local.yml`
elsif server_type == 'webserver'
  `cp tapjoyads/config/newrelic-web.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'website'
  `cp tapjoyads/config/newrelic-website.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'dashboard'
  `cp tapjoyads/config/newrelic-dashboard.yml tapjoyads/config/newrelic.yml`
elsif server_type == 'util'
  `cp tapjoyads/config/newrelic-util.yml tapjoyads/config/newrelic.yml`
  `cp tapjoyads/config/local-util.yml tapjoyads/config/local.yml`
end

if server_type == 'webserver'
  `cp -f tapjoyads/db/webserver.sqlite tapjoyads/db/production.sqlite`
  `chmod 444 tapjoyads/db/production.sqlite`
  `cp tapjoyads/config/database-webserver.yml tapjoyads/config/database.yml`
else
  `cp tapjoyads/config/database-default.yml tapjoyads/config/database.yml`
end

Dir.chdir "tapjoyads" do
  if server_type == "dev"
    `bundle install`
  else
    `bundle install --deployment`
  end
end

puts "Restarting unicorn"
system "server/start_or_reload_unicorn.rb"

system "server/restart_job_daemon.rb"
