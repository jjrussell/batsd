#!/usr/bin/env ruby

# Fixes the missed payments that were missed due to the mssql outage from 2:37 - 5:15 PM EST on 12/27/09

include RightAws

start_time = Time.parse("2:37 PM EST", Time.utc(2009, 12, 27)).utc
end_time = Time.parse("5:15 PM EST", Time.utc(2009, 12, 27)).utc

next_token = nil
count = 0
begin
  where_clause = "(type='offer' or type='install') and `updated-at`>'#{start_time.to_f}' and `updated-at`< '#{end_time.to_f}'"
  response = SimpledbResource.select('reward', '*', where_clause, nil, next_token)
  next_token = response[:next_token]
  items = response[:items]
  
  items.each do |item|
    message = item.serialize
    SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN).send_message(message)
    count += 1
  end
  puts "Sent #{count} items to the queue."
end while next_token != nil

puts "DONE. Sent a total of #{count} items to the money txn queue."
