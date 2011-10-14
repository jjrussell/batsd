namespace :admin do

  # admin:restart_apache
  desc "Restarts apache on all the webservers"
  task :restart_apache do
    system("script/cloudrun 'webserver' 'sleep 5 ; sudo /etc/init.d/apache2 stop ; sleep 2 ; sudo /etc/init.d/apache2 start' 'ubuntu' 'serial'")
  end

  # admin:view_long_jobs
  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun 'masterjobs jobserver' 'uptime ; ls -lh tapjoyserver/tapjoyads/tmp/*sdb* tapjoyserver/tapjoyads/tmp/*s3* tapjoyserver/tapjoyads/tmp/*json* 2> /dev/null'")
  end

  # admin:sync_db
  desc "Copies the production database to the development database"
  task :sync_db do
    database_yml = YAML::load_file("config/database.yml")
    source       = database_yml['production_slave']
    dest         = database_yml['development']
    dump_file    = "tmp/#{source['database']}.sql"
    dump_file2   = "tmp/#{source['database']}2.sql"

    print("Backing up the production database... ")
    time = Benchmark.realtime do
      system("mysqldump -u #{source['username']} --password=#{source['password']} -h #{source['host']} --single-transaction --ignore-table=#{source['database']}.conversions --ignore-table=#{source['database']}.payout_infos #{source['database']} > #{dump_file}")
      system("mysqldump -u #{source['username']} --password=#{source['password']} -h #{source['host']} --single-transaction --no-data #{source['database']} conversions payout_infos > #{dump_file2}")
    end
    puts("finished in #{time} seconds.")

    system("rake db:drop")
    system("rake db:create")

    print("Restoring backup to the development database... ")
    time = Benchmark.realtime do
      system("mysql -u #{dest['username']} --password=#{dest['password']} -h #{dest['host']} #{dest['database']} < #{dump_file}")
      system("mysql -u #{dest['username']} --password=#{dest['password']} -h #{dest['host']} #{dest['database']} < #{dump_file2}")
    end
    puts("finished in #{time} seconds.")
    system("rm -f #{dump_file}")
    system("rm -f #{dump_file2}")
  end

  desc "Reconfigure syslog-ng"
  task :reconfigure_syslog_ng do
    system("script/cloudrun 'masterjobs jobserver webserver website dashboard games testserver' 'sudo /home/webuser/tapjoyserver/server/syslog-ng/configure.rb 2>&1' 'ubuntu'")
  end

  desc "Update geoip databse"
  task :geoipupdate do
    system("script/cloudrun 'masterjobs jobserver webserver website dashboard games' 'tapjoyserver/server/update_geoip.rb' 'webuser' 'serial'")
  end

end
