#!/usr/bin/env ruby

require 'rubygems'
require 'patron'

path_list = [
  '/cron/get_ad_network_data'
  ]

loop {
  sess = Patron::Session.new
  sess.base_url = 'http://localhost:3000'

  sess.username = 'cron'
  sess.password = 'y7jF0HFcjPq'
  sess.auth_type = :basic

  response = sess.get(path_list[0])

  puts "Downloaded complete: #{response.body}"  
}
