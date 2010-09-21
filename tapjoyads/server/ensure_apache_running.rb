#!/usr/bin/env ruby

if `ps aux | grep -v grep | grep -i passenger`.empty?
  `sudo /etc/init.d/apache2 restart`
end
