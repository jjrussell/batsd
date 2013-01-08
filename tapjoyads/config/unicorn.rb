# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.

base_dir = File.expand_path("../../../", __FILE__)
server_type = `#{base_dir}/server/server_type.rb`

app_dir = "#{base_dir}/tapjoyads"
working_directory app_dir

worker_processes 16
timeout 20

Rainbows! do
  use :EventMachine
  worker_connections 100

  # Load app into the master before forking workers for super-fast
  # worker spawn times
  preload_app true

  if ENV['RACK_ENV'] == 'development' && require('dotenv')
    ENV['PORT'] ||= Dotenv.load['PORT']
  end

  # listen on both a Unix domain socket and a TCP port,
  # we use a shorter backlog for quicker failover when busy
  if server_type == "dev"
    listen "0.0.0.0:#{ENV['PORT'] || '8080'}"
  else
    listen("/tmp/tapjoy.socket", :backlog => 2048)
  end

  # feel free to point this anywhere accessible on the filesystem
  user 'webuser', 'webuser'  unless server_type == "dev"

  # set up pids directory just for sure
  FileUtils.mkdir_p("#{app_dir}/pids")
  pid "#{app_dir}/pids/unicorn_#{Process.pid}.pid"

  # When in dev, send logs to the console
  unless server_type == "dev"
    stderr_path "/mnt/log/unicorn/stderr.log"
    stdout_path "/mnt/log/unicorn/stdout.log"
  end

  # http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
  if GC.respond_to?(:copy_on_write_friendly=)
    GC.copy_on_write_friendly = true
  end

  if GC.respond_to?(:enable_stats)
    GC.enable_stats
  end


  before_fork do |server, worker|
    # the following is highly recomended for Rails + "preload_app true"
    # as there's no need for the master process to hold a connection
    defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

    ##
    # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
    # immediately start loading up a new version of itself (loaded with a new
    # version of our app). When this new Unicorn is completely loaded
    # it will begin spawning workers. The first worker spawned will check to
    # see if an .oldbin pidfile exists. If so, this means we've just booted up
    # a new Unicorn and need to tell the old one that it can now die. To do so
    # we send it a QUIT.
    #
    # Using this method we get 0 downtime deploys.

    Dir.glob("#{app_dir}/pids/*.oldbin").each do |old_pid|
      if File.exists?(old_pid) && server.pid != old_pid
        begin
          sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
          Process.kill(sig, File.read(old_pid).to_i)
        rescue Errno::ENOENT, Errno::ESRCH
          # someone else did our job for us
        end
      end
    end
  end

  after_fork do |server, worker|
    # Unicorn master loads the app then forks off workers - because of the way
    # Unix forking works, we need to make sure we aren't using any of the parent's
    # sockets, e.g. db connection

    defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
    defined?(Mc) and Mc.reset_connection
    defined?(SimpledbCache) and SimpledbCache.reset_connection
    defined?(DedupeCache) and DedupeCache.reset_connection
    defined?(SimpledbResource) and SimpledbResource.reset_connection
    defined?(VerticaCluster) and VerticaCluster.reset_connection
    defined?(AnalyticsLogger) and AnalyticsLogger.after_fork

    $redis_connections.each{ |conn| conn.reset_proxy! }

    defined?(GEOIP) and GEOIP.reconnect!
    at_exit { defined?(NewRelic) and NewRelic::Agent.shutdown({:force_send=>true}) }
  end

  # Read environment settings from .env. This allows the environment to be changed during a unicorn
  # upgrade via USR2
  before_exec do |server|
    env_files = [ File.join(ENV['HOME'], '.connect.env'), File.join(app_dir, '.env') ]

    env_files.each do |env_file|
      if File.exists?(env_file)
        File.foreach(env_file) do |line|
          k,v = line.split('=').map{ |v| v.strip }
          ENV[k]=v
        end
      end
    end
  end
end
