#!/usr/bin/env ruby

if ENV['USER'] != 'webuser'
  puts 'This script must be run by webuser.'
  exit
end

server_type = `/home/webuser/tapjoyserver/server/server_type.rb`
exit if server_type == 'testserver'

require 'rubygems'
require 'yaml'
require 'aws-sdk'

LOCAL_BASE    = '/home/webuser/tapjoyserver/tapjoyads/data/'

AWS_CONFIG    = YAML::load_file('/home/webuser/.tapjoy_aws_credentials.yaml')['production']
BUCKET        = AWS::S3.new(:access_key_id => AWS_CONFIG['access_key_id'], :secret_access_key => AWS_CONFIG['secret_access_key']).buckets['tapjoy']

GEOIP_VERSION = BUCKET.objects['GeoIPCity.version'].read
GEOIP_FILE    = "#{GEOIP_VERSION}-GeoIPCity.dat"

if File.exists? "#{LOCAL_BASE}#{GEOIP_FILE}"
  puts "GeoIP data is already up-to-date.  #{GEOIP_VERSION}"
else
  File.open("#{LOCAL_BASE}#{GEOIP_FILE}", 'w') do |f|
    f.write(BUCKET.objects[GEOIP_FILE].read)
  end
  unless File.exists? "#{LOCAL_BASE}GeoIPCity.dat"
    File.open("#{LOCAL_BASE}GeoIPCity.dat", 'w') do |f|
      # Backwards compatibility
      f.write(BUCKET.objects[GEOIP_FILE].read)
    end
  end
  puts "Updated GeoIP database.  #{GEOIP_VERSION}"
end
