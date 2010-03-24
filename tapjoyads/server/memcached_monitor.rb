#!/usr/bin/env ruby
# Monitors local memcached server. If it can't connect to a local memcached server, then it
# will run launch_memcached.rb

require 'logger'
require 'socket'
logger = Logger.new("/home/webuser/memcached_monitor.log", 7, 10000000)

# Get internal ip address
ifconfig = `/sbin/ifconfig`
ip_address = ifconfig.match(/inet addr:(.*?)\s/)[1]

begin
  loop do
    t = TCPSocket.new(ip_address, 11211)
    t.close
    retry_count = 0
    logger.info "OK"
    sleep(30)
  end
rescue Errno::ECONNREFUSED
  logger.error "No connection could be made to #{ip_address}:11211."
  sleep(5)
  if retry_count < 3
    logger.error "Retrying."
    retry_count += 1
    retry
  else
    logger.error "Restarting memcached."
    exec "/home/webuser/server/launch_memcached.rb"
  end
end