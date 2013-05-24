namespace :db do
  # Display a message with updating dots while running a command. Useful for commands that take a while to run.
  def runner(msg, cmd, env={})
    dots = Thread.new do
      (1..5).cycle do |count|
        print "\r#{msg}"
        print ('.' * count).ljust(5)
        sleep 0.1
      end
    end

    begin
      dots.run
      time = Benchmark.realtime do
        fork {
          env.each { |k,v| ENV[k] = v }
          exec(cmd)
        }
        Process.wait
      end
    ensure
      dots.kill
    end

    puts "\r#{msg}... finished in #{time} seconds."
  end

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

  DATABASE_YML = YAML.load(ERB.new(File.read("config/database.yml")).result)
  SOURCE       = DATABASE_YML['production_slave']
  DEST         = DATABASE_YML[Rails.env]
  DUMP_FILE    = "tmp/#{SOURCE['database']}.sql"
  DUMP_FILE2   = "tmp/#{SOURCE['database']}2.sql"

  desc "Copies the production database to the development database"

  task :sync => [:fetch, :restore, :remove_tmp_files]

  task :fetch do
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?

    tables_to_ignore = %w( gamers gamer_profiles gamer_devices app_reviews conversions payout_infos favorite_apps invitations )

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

    runner("Backing up the production database", "mysqldump #{options} #{ignore_options} #{SOURCE['database']} > #{DUMP_FILE}")
    runner("Backing up non-data tables", "mysqldump #{options} #{SOURCE['database']} #{nodata_options} > #{DUMP_FILE2}")
  end

  task :restore do
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?
    raise "You must run db:fetch before restoring" unless File.exist?(DUMP_FILE) && File.exist?(DUMP_FILE2)

    Rake.application.invoke_task('db:drop')
    Rake.application.invoke_task('db:create')

    options = [
      "--user=#{DEST['username']}",
      "--password=#{DEST['password']}",
      "--host=#{DEST['host']}",
    ].join(' ')

    runner("Restoring data backup to the #{Rails.env} database", "mysql #{options} #{DEST['database']} < #{DUMP_FILE}")
    runner("Restoring non-data backup to the #{Rails.env} database", "mysql #{options} #{DEST['database']} < #{DUMP_FILE2}")
  end

  task :remove_tmp_files do
    raise "Must be run from development or staging mode" unless Rails.env.development? || Rails.env.staging?
    puts("removing #{DUMP_FILE} #{DUMP_FILE2}")
    system("rm -f #{DUMP_FILE}")
    system("rm -f #{DUMP_FILE2}")
  end

  namespace :schema do
    desc "Sync the mysql schema with the sqlite database used for development webserver boxes"
    task :sync do
      schema_file  = "db/schema-dev.rb"

      env = {'SCHEMA' => schema_file}
      runner("Dumping mysql schema to #{schema_file}", "bundle exec rake db:schema:dump > dev/null", env)
      runner("Loading schema file into sqlite", "bundle exec rake db:schema:load > /dev/null", env.merge('MACHINE_TYPE' => 'webserver'))
    end
  end

  task :truncate => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each { |t| conn.execute("TRUNCATE #{t}") }
  end
end
