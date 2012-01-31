#!/usr/bin/env ruby

free_mem  = `free -m`.split("\n")[2].split[3].to_i
threshold = 250 + rand(250)

if free_mem < threshold
  `sudo /etc/init.d/apache2 reload`
  `echo '#{Time.now}' >> /mnt/log/apache_reloads.log`
end

exit
