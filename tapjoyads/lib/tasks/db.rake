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

  DATABASE_YML = YAML::load_file("config/database.yml")
  SOURCE       = DATABASE_YML['production_slave']
  DEST         = DATABASE_YML[Rails.env]
  DUMP_FILE    = "tmp/#{SOURCE['database']}.sql"
  DUMP_FILE2   = "tmp/#{SOURCE['database']}2.sql"

  desc "Copies the production database to the development database"
  task :sync do
    download
    import_files
    remove_files
  end

  task :download do
    download
  end

  task :import do
    import_files
  end

  task :remove_tmp_files do
    remove_tmp_files
  end

  def download
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?
    print("Backing up the production database... ")
    tables_to_ignore = %w( gamers gamer_profiles gamer_devices app_reviews conversions payout_infos )
    time = Benchmark.realtime do

      options = [
        "--user=#{SOURCE['username']}",
        "--password=#{SOURCE['password']}",
        "--host=#{SOURCE['host']}",
        "--single-transaction",
      ].join(' ')

      ignore_options = tables_to_ignore.map do |table|
        "--ignore-table=#{SOURCE['database']}.#{table}"
      end.join(' ')

      nodata_options = [ "--no-data", tables_to_ignore.join(' ') ].join(' ')

      system("mysqldump #{options} #{ignore_options} #{SOURCE['database']} > #{DUMP_FILE}")
      system("mysqldump #{options} #{SOURCE['database']} #{nodata_options} > #{DUMP_FILE2}")
    end
    puts("finished in #{time} seconds.")
  end

  def import_files
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?

    Rake.application.invoke_task('db:drop')
    Rake.application.invoke_task('db:create')

    print("Restoring backup to the #{Rails.env} database... ")
    time = Benchmark.realtime do
      options = [
        "--user=#{DEST['username']}",
        "--password=#{DEST['password']}",
        "--host=#{DEST['host']}",
      ].join(' ')
      [ DUMP_FILE, DUMP_FILE2 ].each do |file|
        system("mysql #{options} #{DEST['database']} < #{file}")
      end
    end
    puts("finished in #{time} seconds.")
  end

  def remove_tmp_files
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?
    system("rm -f #{DUMP_FILE}")
    system("rm -f #{DUMP_FILE2}")
    puts("removing #{DUMP_FILE} #{DUMP_FILE2}")
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
