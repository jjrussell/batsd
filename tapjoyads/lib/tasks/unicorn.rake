namespace :unicorn do

  desc "Reload unicorn"
  task :reload, :servers do |task, args|
    servers = args[:servers] || 'masterjobs jobserver dashboard website webserver'
    system("script/cloudrun '#{servers}' 'tapjoyserver/server/start_or_reload_unicorn.rb' 'webuser'")
  end

  desc "Show master processes"
  task :show_masters, :servers do |task, args|
    servers = args[:servers] || 'masterjobs jobserver dashboard website webserver'
    system("script/cloudrun '#{servers}' 'uptime ; ps aux | grep -v grep | grep unicorn_rails | grep master' 'webuser'")
  end

  desc "Count worker processes"
  task :count_workers, :servers do |task, args|
    servers = args[:servers] || 'masterjobs jobserver dashboard website webserver'
    system("script/cloudrun '#{servers}' 'uptime ; ps aux | grep -v grep | grep unicorn_rails | grep worker | wc -l' 'webuser'")
  end

end
