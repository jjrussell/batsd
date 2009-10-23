#!/usr/bin/env ruby

require 'rubygems'
require 'patron'
require 'logger'

$logger = Logger.new('run_jobs.log')


path_list = [
  '/cron/get_ad_network_data'
  ]

loop {
  begin
    sess = Patron::Session.new
    sess.base_url = 'http://localhost'

    sess.username = 'cron'
    sess.password = 'y7jF0HFcjPq'
    sess.auth_type = :basic

    response = sess.get(path_list[0])

    $logger.info "Downloaded complete: #{response.body}"
  rescue => e
    $logger.warn "Exception: #{e}"
  end
}
