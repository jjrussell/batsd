#!/usr/bin/env ruby
#
# Converts the pinger-tapjoy-udids file into separate files, one for each app.
#
# Their file is in the form:
# 00000000-0000-1000-8000-0016CB897053,201dd450-6261-46f9-8136-92b2f9b8d643,323ad9e3-ad28-4eae-a9a0-d908b759225f
# 00000000-0000-1000-8000-0016CB897053,6b69461a-949a-49ba-b612-94c8e7589642,577235fd-5fda-4d67-a1ea-5205605795aa 
# <UDID>,<app_id>,<app_pw>
# 
# The file names generated will be "pinger.<app_id>.txt", each with one udid per line.
# The files output will be suitable for use by the import_udids.rb script.

filename = ARGV.first

out_files = {}

File.open(filename, "r") do |file|
  while (line = file.gets)
    parts = line.split(',')
    udid = parts[0]
    app_key = parts[1]
    
    out_file = out_files[app_key]
    unless file
      out_file = File.new("pinger.#{app_key}.txt", 'w')
      out_files[app_key] = out_file
    end
    
    out_file.puts(udid)
  end
end

out_files.each do |key, file|
  file.close
end

puts "done"