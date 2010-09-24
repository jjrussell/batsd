#!/usr/bin/env ruby

require 'timeout'

def passenger_responding?
  begin
    Timeout.timeout(20) do
      result = `curl -s http://localhost:9898/healthz`
      return result == 'OK'
    end
  rescue Timeout::Error
    return false
  end
end

unless passenger_responding?
  `sudo /etc/init.d/apache2 restart`
  `date >> /mnt/log/apache_restarts.log`
end
