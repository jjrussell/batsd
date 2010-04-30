ip = `/sbin/ifconfig`.match(/inet addr:(.*?)\s/)[1]
pid = "/home/webuser/memcached.pid"

God.watch do |w|
  w.name = "memcached"
  w.interval = 5.seconds
  w.start = "/usr/local/bin/memcached -u webuser -c 2048 -m 6800 -l #{ip} -d -P #{pid}"
  w.stop = "/bin/cat #{pid} | /usr/bin/xargs /bin/kill"
  w.pid_file = pid
  w.grace = 5.seconds

  # clean pid files before start if necessary
  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
