namespace :db do

  namespace :schema do
    desc "Create a db/schema.rb file from a specific database"
    task :dump_database => [:environment, :load_config] do
      require 'active_record/schema_dumper'
      filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
      database = ENV['DATABASE'] || Rails.env
      File.open(filename, "w:utf-8") do |file|
        ActiveRecord::Base.establish_connection(database)
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end

  desc "Copies the production database to the development database"
  task :sync do
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?

    database_yml = YAML::load_file("config/database.yml")
    source       = database_yml['production_slave']
    dest         = database_yml[Rails.env]
    dump_file    = "tmp/#{source['database']}.sql"
    dump_file2   = "tmp/#{source['database']}2.sql"

    print("Backing up the production database... ")
    tables_to_ignore = %w( gamers gamer_profiles gamer_devices app_reviews conversions payout_infos )
    time = Benchmark.realtime do

      options = [
        "--user=#{source['username']}",
        "--password=#{source['password']}",
        "--host=#{source['host']}",
        "--single-transaction",
      ].join(' ')

      ignore_options = tables_to_ignore.map do |table|
        "--ignore-table=#{source['database']}.#{table}"
      end.join(' ')

      nodata_options = [ "--no-data", tables_to_ignore.join(' ') ].join(' ')

      system("mysqldump #{options} #{ignore_options} #{source['database']} > #{dump_file}")
      system("mysqldump #{options} #{source['database']} #{nodata_options} > #{dump_file2}")
    end
    puts("finished in #{time} seconds.")

    Rake.application.invoke_task('db:drop')
    Rake.application.invoke_task('db:create')

    print("Restoring backup to the #{Rails.env} database... ")
    time = Benchmark.realtime do
      options = [
        "--user=#{dest['username']}",
        "--password=#{dest['password']}",
        "--host=#{dest['host']}",
      ].join(' ')
      [ dump_file, dump_file2 ].each do |file|
        system("mysql #{options} #{dest['database']} < #{file}")
      end
    end
    puts("finished in #{time} seconds.")
    system("rm -f #{dump_file}")
    system("rm -f #{dump_file2}")
  end

  namespace :schema do
    desc "Sync the mysql schema with the sqlite database used for development webserver boxes"
    task :sync do
      schema_file  = "db/schema-dev.rb"

      print "Dumping mysql schema to #{schema_file}..."
      time = Benchmark.realtime do
        fork {
          ENV['SCHEMA'] = schema_file
          exec('bundle exec rake db:schema:dump')
        }
        Process.wait
      end
      puts "finished in #{time} seconds."

      print "Loading schema file into sqlite..."
      time = Benchmark.realtime do
        fork {
          ENV['SCHEMA'] = schema_file
          ENV['MACHINE_TYPE'] = 'webserver'
          exec('bundle exec rake db:schema:load')
        }
        Process.wait
      end
      puts "finished in #{time} seconds."
    end
  end
end
