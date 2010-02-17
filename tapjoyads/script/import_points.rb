#!/usr/bin/env ruby

include RightAws



filename = ARGV[2]

count = 0

File.open(filename, "r") do |file|
  while (line = file.gets)
    count += 1

    parts = line.split(' ')
    
    next if parts.length < 3 || count < 3
    
    app_id = parts[0].downcase
    udid = parts[1].downcase
    points = parts[2]
  
    p = PointPurchases.new(:key => "#{udid}.#{app_id}")
    p.points = points
    p.save
  
    puts "Count: #{count}" if count % 100 == 0
    sleep(1) if count % 100 == 0
    
  end
  
  
end
    
  