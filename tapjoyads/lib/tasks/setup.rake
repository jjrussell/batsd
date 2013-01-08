desc "Set up a development environment"
task :setup => %w(setup:git setup:rvm setup:tmp setup:configs setup:geoip setup:bundle)

namespace :setup do
  def say(message)
    # Placeholder to allow colorizing
    puts message
  end

  def run(message, *commands)
    say "#{message}..."

    commands.each do |command|
      output = `#{command}`

      unless $?.success?
        say output
        say "Command failed: #{command}"
        exit(255)
      end
    end
  end

  task :git do
    run "Adding tapjoy git remote", "git remote | grep tapjoy || git remote add tapjoy git@github.com:Tapjoy/connect.git"
    # This will fail inside a vagrant install. We should find a long-term solution
    #run "Adding pre-commit hooks", "ln -s ../.pre-commit ../.git/hooks/"
  end

  task :rvm do
    if !system("which rvm > /dev/null")
      say "RVM is not installed. Skipping ruby setup"
    elsif !File.exists?(".rvmrc")
      ruby = "1.8.7-p358"
      run "Installing #{ruby} if needed", "rvm list rubies | grep #{ruby} || rvm install #{ruby}"
      File.open(".rvmrc", "w+") { |f| f.puts "rvm use #{ruby}" }
      run "Marking rvmrc trusted", "rvm rvmrc trust #{Dir.pwd}"
    end
  end

  task :tmp do
    Dir.mkdir "tmp" unless File.exists?("tmp")
  end

  task :configs do
    unless File.exists?("config/newrelic.yml")
      run "Copying newrelic config", "cp config/newrelic-test.yml config/newrelic.yml"
    end

    unless File.exists?("config/local.yml")
      run "Copying local defaults", "cp config/local-default.yml config/local.yml"
    end

    unless File.exists?("config/database.yml")
      run "Copying database config", "cp config/database-default.yml config/database.yml"
    end
  end

  task :geoip do
    run "Downloading geoip data",
      "curl http://s3.amazonaws.com/dev_tapjoy/rails_env/GeoLiteCity.dat.gz | gunzip > data/GeoIPCity.dat",
      "touch data/GeoIPCity.version"
  end

  task :bundle do
    run "Installing bundle", "bundle install"
  end
end
