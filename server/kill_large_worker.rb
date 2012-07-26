##
# Unicorn workers procs grow really fast and trigger OOM_Killer
# Prempt OOM_Killer by gracefully killing the fattest unicorn in low-mem conditions
#

## Free memory threshold. Kill a worker if less than this amount of RAM is free.
FREE_RAM_REQUIRED_MB=500

procs=`ps -eo pid,rss,cmd  | grep "unicorn worker" | grep -v grep`.to_s
workers = []
procs.each_line {|s| workers << s.split(' ', 3)}

def kill_fattest_worker(workers)
  workers.sort! {|x,y| y[1].to_i <=> x[1].to_i}
  print "#{Time.now} - killing worker #{workers[0][0]} with ram #{workers[0][1]}\n"
  %x{kill -QUIT #{workers[0][0]}}
end

def need_more_ram?
  meminfo = `cat /proc/meminfo`
  free = 100000000
  meminfo.each_line do |l|
    tokens = l.split
    free = tokens[1].to_i if tokens[0] == 'MemFree:'
  end
  print "#{Time.now} - free = #{free/1000}\n"
  (free/1000) < FREE_RAM_REQUIRED_MB
end

## Kill the fattest worker if not enough RAM is free
kill_fattest_worker(workers) if need_more_ram? && workers && workers.size > 0
