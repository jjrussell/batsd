#!/usr/bin/env ruby

# this should run on the syslog-ng servers every 5 minutes
#
# makes sure that all logfiles from the previous 24 hours have been uploaded to s3.
# once a file is uploaded, keep a copy for 48 hours before deleting.

require 'rubygems'
require 'uuidtools'
require 'aws-sdk'

ebs_base   = '/ebs/log/rails-web_requests'
local_base = '/mnt'
now        = Time.now.utc
end_time   = Time.at(now.to_i - 300 - (now.to_i % 60)).utc
time       = end_time - 86400 # 24 hours
s3         = AWS::S3.new(:access_key_id => 'AKIAIIKZSMGHPF4Q6JAA', :secret_access_key => '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')
bucket     = s3.buckets['web-requests']

while time < end_time do
  filename     = "#{time.strftime('%Y-%m-%d-%H%M')}"
  logfile_path = "#{ebs_base}/#{filename}.log"

  if File.exists?(logfile_path)
    unique_id     = UUIDTools::UUID.random_create.hexdigest
    tmpfile_path  = "#{logfile_path}.uploading.#{unique_id}"
    gzipfile_path = "#{local_base}/#{filename}.#{unique_id}.sdb.gz"
    s3_path       = "syslog-ng/#{time.strftime('%Y-%m-%d')}/#{time.strftime('%H%M')}-#{unique_id}.sdb.gz"

    File.rename(logfile_path, tmpfile_path)

    `gzip -c #{tmpfile_path} > #{gzipfile_path}`

    s3_object = bucket.objects[s3_path]
    s3_object.write(:file => gzipfile_path)

    File.delete(gzipfile_path)
    File.rename(tmpfile_path, "#{logfile_path}.uploaded.#{unique_id}")
  end

  delete_time = time - 172800 # 48 hours
  Dir.glob("#{ebs_base}/#{delete_time.strftime('%Y-%m-%d-%H%M')}.log.uploaded.*").each do |filename|
    File.delete(filename)
  end

  time += 60
end
