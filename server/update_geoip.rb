#!/usr/bin/env ruby

if ENV['USER'] != 'webuser'
  puts 'This script must be run by webuser.'
  exit
end

server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
exit if server_type == 'test'

require 'rubygems'
require 'yaml'
require 'aws-sdk'

LOCAL_BASE = '/home/webuser/GeoIP/'
GEOIP_FILE = 'GeoIPCity.dat'
GEOIP_MD5  = 'GeoIPCity.md5'
AWS_CONFIG = YAML::load_file('/home/webuser/.tapjoy_aws_credentials.yaml')['production']
BUCKET     = AWS::S3.new(:access_key_id => AWS_CONFIG['access_key_id'], :secret_access_key => AWS_CONFIG['secret_access_key']).buckets['tapjoy']

local_md5  = Digest::MD5.hexdigest(File.read("#{LOCAL_BASE}#{GEOIP_FILE}"))
remote_md5 = BUCKET.objects[GEOIP_MD5].read

if local_md5 == remote_md5
  puts "GeoIP database is already up-to-date."
else
  File.open("#{LOCAL_BASE}#{GEOIP_FILE}.new", 'w') do |f|
    f.write(BUCKET.objects[GEOIP_FILE].read)
  end
  File.rename("#{LOCAL_BASE}#{GEOIP_FILE}.new", "#{LOCAL_BASE}#{GEOIP_FILE}")
  puts `/home/webuser/tapjoyserver/server/start_or_reload_unicorn.rb`
  puts "Updated GeoIP database."
end
