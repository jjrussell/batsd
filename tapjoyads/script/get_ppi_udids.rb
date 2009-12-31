#!/usr/bin/env ruby

# Gets a list of udids who earned currency within a certain period of time

#usage: script/runner -e production script/get_ppi_udids.rb <app_id> <outfile>

include RightAws

app_id = ARGV[2]
outfile = ARGV[3]

next_token = nil
count = 0

file = File.new(outfile, "w")

begin
  where_clause = "advertiser_app_id = '#{app_id}' and installed != ''"
  response = SimpledbResource.select('store-click', '*', where_clause, nil, next_token)
  next_token = response[:next_token]
  items = response[:items]
  
  items.each do |item|
    udid = item.key.split('.')[0]
    time = item.get('installed')
    file.syswrite("#{udid},#{time}\n")
    count += 1
  end
  puts "Wrote #{count} items to #{outfile}."
end while next_token != nil

file.close

puts "DONE. Wrote a total of #{count} items to #{outfile}."
