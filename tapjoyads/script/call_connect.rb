#!/usr/bin/env ruby
require 'uri'
require 'net/http'

arr = []
count = 0
messages = 0
bad = 0

app_id = ARGV.first
name = ARGV[1]
f = File.open(name, "r") 
lines = []
f.each_line do |line|
  lines.push line
end

i = 0
while i < lines.length do
  Thread.new do
    begin
      start = i
      (0..999).each do |j|
        if start + j < lines.length 
          url = "http://ws.tapjoyads.com/connect?udid=#{lines[start + j]}&app_id=#{app_id}&library_version=server&device_os_version=3.0&app_version=1.0&device_type=iPhone"
          #puts "#{url}\n" if j == 50
          Net::HTTP.get(URI.parse(url))
        end
        puts "i: #{start}     j: #{j}\n" if j % 100 == 0
      end
    rescue => e
      puts "Bad line: #{e}\n"
      retry
    end
    sleep(20)
  end
  i += 1000
  sleep(15)
  puts "i: #{i}\n" if i % 50 == 0
end

puts "Waiting 50 minutes to finish...\n"
sleep(3000)
