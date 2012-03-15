#!/usr/bin/env ruby

base_dir = File.expand_path("../../", __FILE__)

free_mem  = `free -m`.split("\n")[2].split[3].to_i
threshold = 500 + rand(250)

if free_mem < threshold
  `#{base_dir}/server/start_or_reload_unicorn.rb`
  `echo '#{Time.now}' >> /mnt/log/unicorn_reloads.log`
end

exit
