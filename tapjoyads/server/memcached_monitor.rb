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
    logger.info "OK"
    sleep(30)
  end
rescue
  logger.error "No connection could be made to #{ip_address}:11211. Restarting memcached"
  `/home/webuser/server/launch_memcached.rb`
end