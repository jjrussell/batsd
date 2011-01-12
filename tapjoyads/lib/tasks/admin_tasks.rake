namespace :admin do
  
  # admin:restart_apache
  desc "Restarts apache on all the webservers"
  task :restart_apache do
    system("script/cloudrun 'webserver' 'sleep 5 ; sudo /etc/init.d/apache2 stop ; sleep 2 ; sudo /etc/init.d/apache2 start' 'ubuntu' 'remove_from_lb'")
  end
  
  # admin:view_long_jobs
  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun 'jobserver' 'uptime ; ls -lh tapjoyserver/tapjoyads/tmp/*sdb* tapjoyserver/tapjoyads/tmp/*s3* 2> /dev/null'")
  end
  
  # admin:sync_db
  desc "Copies the production database to the development database"
  task :sync_db do
    database_yml = YAML::load_file("config/database.yml")
    source       = database_yml['production_slave']
    dest         = database_yml['development']
    dump_file    = "tmp/#{source['database']}.sql"
    
    print("Backing up the production database... ")
    time = Benchmark.realtime do
      system("mysqldump -u #{source['username']} --password=#{source['password']} -h #{source['host']} --single-transaction --ignore-table=#{source['database']}.conversions #{source['database']} > #{dump_file}")
    end
    puts("finished in #{time} seconds.")
    
    system("rake db:migrate:reset")
    
    print("Restoring backup to the development database... ")
    time = Benchmark.realtime do
      system("mysql -u #{dest['username']} --password=#{dest['password']} -h #{dest['host']} #{dest['database']} < #{dump_file}")
    end
    puts("finished in #{time} seconds.")
    system("rm -f #{dump_file}")
  end
  
  desc "Prints the apache restarts logs"
  task :view_apache_restarts do
    system("script/cloudrun 'webserver' 'uptime ; if [ -f /mnt/log/apache_restarts.log ] ; then cat /mnt/log/apache_restarts.log ; fi' 'ubuntu'")
  end
  
end
