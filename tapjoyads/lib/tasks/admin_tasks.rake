namespace :admin do
  
  # admin:cleanup_deploys
  desc "Deletes all but the last 15 deploy branches"
  task :cleanup_deploys do
    settings = YAML::load_file("#{RAILS_ROOT}/server/configuration.yaml")
    current_version = settings['config']["api_deploy_version"].to_i
    branches = `svn ls https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/deploy`
    branches.split("/\n").each do |version|
      next if version.to_i > current_version - 15
      puts "Deleting branch: deploy/#{version}"
      `svn delete https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/deploy/#{version} -m 'deleteing old deploy branch'`
    end
  end
  
  # admin:restart_apache
  desc "Restarts apache on all the webservers"
  task :restart_apache do
    system("script/cloudrun 'webserver' 'sleep 5 ; sudo /etc/init.d/apache2 stop ; sleep 2 ; sudo /etc/init.d/apache2 start' 'ubuntu' 'remove_from_lb'")
  end
  
  # admin:view_long_jobs
  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun 'jobserver' 'uptime ; ls -lh tapjoyads/tmp/*sdb* tapjoyads/tmp/*s3* 2> /dev/null'")
  end
  
  # admin:sync_db
  desc "Copies the production database to the development database"
  task :sync_db do
    print("Backing up the production database... ")
    time = Benchmark.realtime do
      system("mysqldump -u tapjoy --password=andoverbusiness1 -h tapjoy-db-rds.cck8zbm50hdd.us-east-1.rds.amazonaws.com --single-transaction --ignore-table=tapjoy_db.conversions tapjoy_db > tmp/tapjoy_db.sql")
    end
    puts("finished in #{time} seconds.")
    
    system("rake db:migrate:reset")
    
    print("Restoring backup to the development database... ")
    time = Benchmark.realtime do
      system("mysql -u tapjoy --password=andoverbusiness1 -h dev-tapjoy-db-rds.cck8zbm50hdd.us-east-1.rds.amazonaws.com tapjoy_db < tmp/tapjoy_db.sql")
    end
    puts("finished in #{time} seconds.")
    system("rm -f tmp/tapjoy_db.sql")
  end
  
  desc "Prints the apache restarts logs"
  task :view_apache_restarts do
    system("script/cloudrun 'webserver' 'uptime ; if [ -f /mnt/log/apache_restarts.log ] ; then cat /mnt/log/apache_restarts.log ; fi' 'ubuntu'")
  end
  
end
