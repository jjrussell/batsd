class Job::QueueUdidReportsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::UDID_REPORTS
    @num_reads = 5
  end
  
private
  
  def on_message(message)
    json = JSON.load(message.to_s)
    offer_id = json['offer_id']
    date_str = json['date']
    date = Time.zone.parse(date_str).beginning_of_day
    conditions = "offer_id = '#{offer_id}' AND created >= '#{date.to_i}' AND created < '#{(date + 1.day).to_i}'"
    fs_path = "tmp/#{offer_id}_#{date.strftime('%Y-%m-%d')}.s3"
    outfile = File.open(fs_path, 'w+')
    
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:domain_name => "rewards_#{i}", :where => conditions) do |reward|
        if reward.udid?
          line = "#{reward.udid},#{reward.created.to_s(:db)},#{reward.country}"
          outfile.puts(line)
        end
      end
    end
    
    if outfile.pos > 0
      bucket = S3.bucket(BucketNames::UDID_REPORTS)
      path = "#{offer_id}/#{date.strftime('%Y-%m')}/#{date.strftime('%Y-%m-%d')}.csv"
      retries = 3
      begin
        outfile.rewind
        bucket.put(path, outfile.read, {}, 'authenticated-read')
      rescue RightAws::AwsError => e
        if retries > 0
          retries -= 1
          sleep(1)
          retry
        else
          raise e
        end
      end
    end
    
  ensure
    outfile.close rescue nil
    File.delete(fs_path) rescue nil
  end

end
