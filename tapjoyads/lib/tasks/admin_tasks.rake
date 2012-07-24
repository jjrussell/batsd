namespace :admin do

  desc "Reloads apache on all the webservers"
  task :reload_apache do
    system("script/cloudrun 'webserver' 'sudo /etc/init.d/apache2 reload ; curl -s localhost:9898/healthz' 'ubuntu' 'serial'")
  end

  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun 'masterjobs jobserver' 'uptime ; ls -lh tapjoyserver/tapjoyads/tmp/*sdb* tapjoyserver/tapjoyads/tmp/*s3* tapjoyserver/tapjoyads/tmp/*json* 2> /dev/null'")
  end

  desc "Copies the production database to the development database"
  task :sync_db do
    puts "DEPRECATED: use `rake db:sync`"
    Rake::Task['db:sync'].execute
  end

  desc "Force chef client run"
  task :run_chef_client, :servers do |task, args|
    servers = args[:servers] || 'masterjobs jobserver website dashboard webserver'
    system("script/cloudrun '#{servers}' 'rvmsudo /usr/local/rvm/gems/ruby-1.8.7-p358/bin/chef-client' 'ubuntu'")
  end

  desc "Update geoip databse"
  task :geoipupdate, :servers do |task, args|
    servers = args[:servers] || 'masterjobs jobserver website dashboard webserver'
    system("script/cloudrun '#{servers}' 'tapjoyserver/server/update_geoip.rb' 'webuser'")
  end

end
