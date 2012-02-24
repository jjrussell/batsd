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
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?

    database_yml = YAML::load_file("config/database.yml")
    source       = database_yml['production_slave']
    dest         = database_yml[Rails.env]
    dump_file    = "tmp/#{source['database']}.sql"
    dump_file2   = "tmp/#{source['database']}2.sql"

    print("Backing up the production database... ")
    time = Benchmark.realtime do
      system("mysqldump -u #{source['username']} --password=#{source['password']} -h #{source['host']} --single-transaction --ignore-table=#{source['database']}.gamers --ignore-table=#{source['database']}.gamer_profiles --ignore-table=#{source['database']}.gamer_devices --ignore-table=#{source['database']}.conversions --ignore-table=#{source['database']}.payout_infos #{source['database']} > #{dump_file}")
      system("mysqldump -u #{source['username']} --password=#{source['password']} -h #{source['host']} --single-transaction --no-data #{source['database']} gamers gamer_profiles gamer_devices conversions payout_infos > #{dump_file2}")
    end
    puts("finished in #{time} seconds.")

    Rake.application.invoke_task('db:drop')
    Rake.application.invoke_task('db:create')

    print("Restoring backup to the #{Rails.env} database... ")
    time = Benchmark.realtime do
      system("mysql -u #{dest['username']} --password=#{dest['password']} -h #{dest['host']} #{dest['database']} < #{dump_file}")
      system("mysql -u #{dest['username']} --password=#{dest['password']} -h #{dest['host']} #{dest['database']} < #{dump_file2}")
    end
    puts("finished in #{time} seconds.")
    system("rm -f #{dump_file}")
    system("rm -f #{dump_file2}")
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
