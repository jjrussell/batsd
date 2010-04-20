##
# Calculates the unique users for each app in our system, and prints the results to stdout.
# Arguments:
#   unique_users.rb <date> [num_hours]
# eg. `unique_users 2010-01-09 1` will calculate the unique users over the first hour fo Jan. 9
# Omit the last argument to calculate the whole day.

STDOUT.sync = true

date = Time.parse("#{ARGV[2]} 00:00 GMT").utc
num_hours = ARGV[3].to_f || 24
date_string = date.iso8601[0,10]

puts "Start date: #{date_string}, num hours: #{num_hours}"

start_time = Time.now

num_apps = SdbApp.count
puts "#{num_apps} total apps in the system."

puts "Num\tAppName\tAppId\tTotalConnects\tUniqueConnects"

app_num = 0
SdbApp.select do |app|
  udids = {}
  app_num += 1
  print "#{app_num}\t#{app.get('name')}\t#{app.key}\t"
  
  where = "path='connect' and app_id='#{app.key}' and time>'#{date.to_f}' and time<'#{(date + num_hours.hours).to_f}'"
  
  total_count = 0
  MAX_WEB_REQUEST_DOMAINS.times do |num|
    total_count += SimpledbResource.count(:domain_name => "web-request-#{date_string}-#{num}", 
        :where => where)
  end
  
  print "#{total_count}\t"
  if total_count == 0
    puts "0"
    next
  end
  
  MAX_WEB_REQUEST_DOMAINS.times do |num|
    SimpledbResource.select(:domain_name => "web-request-#{date_string}-#{num}", :where => where) do |web_request|
      udids[web_request.get('udid')] = true
    end
  end
  
  puts udids.keys.length
end

puts "Done in #{Time.now - start_time} seconds"