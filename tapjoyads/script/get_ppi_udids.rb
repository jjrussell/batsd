#!/usr/bin/env ruby

# Gets a list of udids who earned currency within a certain period of time

#usage: script/runner -e production script/get_ppi_udids.rb <app_id> <outfile>

include RightAws

app_id = ARGV[2]
outfile = ARGV[3]
first_date = ARGV[4]

next_token = nil
count = 0

file = File.new(outfile, "w")

begin
  where_clause = "advertiser_app_id = '#{app_id}' and installed != ''"
  where_clause = where_clause + " and installed > '#{Time.parse(first_date).to_f}'" if first_date
  begin
    response = StoreClick.select(:where => where_clause, :next_token => next_token)
  rescue
    puts "Failed select"
    retry
  end
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
