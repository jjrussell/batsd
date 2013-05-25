namespace :admin do
  JOBSERVERS = %w( masterjobs jobserver queues-nodb )
  SERVER_TYPES = JOBSERVERS + %w( website dashboard webserver connect offers )

  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun '#{JOBSERVERS}' 'uptime ; ls -lh tapjoyserver/tmp/*sdb* tapjoyserver/tmp/*s3* tapjoyserver/tmp/*json* 2> /dev/null'")
  end

  desc "Copies the production database to the development database"
  task :sync_db do
    puts "DEPRECATED: use `rake db:sync`"
    Rake::Task['db:sync'].execute
  end

  desc "Force chef client run"
  task :run_chef_client, :servers do |task, args|
    servers = args[:servers] || SERVER_TYPES
    system("script/cloudrun '#{servers}' 'rvmsudo /usr/local/rvm/gems/ruby-1.8.7-p358/bin/chef-client' 'ubuntu'")
  end

  desc "Update geoip databse"
  task :geoipupdate, :servers do |task, args|
    servers = args[:servers] || SERVER_TYPES
    system("script/cloudrun '#{servers}' 'tapjoyserver/server/update_geoip.rb' 'webuser'")
  end

end
