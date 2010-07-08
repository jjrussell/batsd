#!/usr/bin/env ruby

# Gets a list of udids who earned currency within a certain period of time

start_time = Time.parse("12:00 AM EST", Time.utc(2009, 12, 23)).utc
end_time = Time.parse("9:00 PM EST", Time.utc(2009, 12, 29)).utc

app_id = ARGV[2]
outfile = ARGV[3]

next_token = nil
count = 0

file = File.new(outfile, "w")

begin
  where_clause = "publisher_app_id = '#{app_id}' and (type='offer' or type='install') and created >'#{start_time.to_f}' and created< '#{end_time.to_f}'"
  response = SimpledbResource.select('reward', '*', where_clause, nil, next_token)
  next_token = response[:next_token]
  items = response[:items]
  
  items.each do |item|
    userid = item.get('publisher_user_id')
    currency = item.get('currency_reward')
    time = item.get('sent_currency')
    file.syswrite("#{userid},#{currency},#{time}\n")
    count += 1
  end
  puts "Wrote #{count} items to #{outfile}."
end while next_token != nil

file.close

puts "DONE. Wrote a total of #{count} items to #{outfile}."
