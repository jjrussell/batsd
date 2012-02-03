# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
app_dir = "/home/webuser/tapjoyserver/tapjoyads"
server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
worker_processes %w(test util web).include?(server_type) ? 18 : 36
working_directory app_dir

# Load app into the master before forking workers for super-fast
# worker spawn times
preload_app true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/tmp/tapjoy.socket"

# feel free to point this anywhere accessible on the filesystem
user 'webuser', 'webuser'

pid "#{app_dir}/pids/unicorn.pid"
stderr_path "/mnt/log/unicorn/stderr.log"
stdout_path "/mnt/log/unicorn/stdout.log"

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
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

  old_pid = "#{server.config[:pid]}.oldbin"

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection

  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
  defined?(Mc) and Mc.reset_connection
  defined?(SimpledbResource) and SimpledbResource.reset_connection
  defined?(VerticaCluster) and VerticaCluster.reset_connection

  # Redis and Memcached would go here but their connections are established
  # on demand, so the master never opens a socket
end
