class UdidReports

  def self.queue_daily_jobs
    start_time = Time.zone.now.beginning_of_day - 1.day
    end_time   = start_time + 1.day
    date_str   = start_time.strftime('%Y-%m-%d')

    Offer.find_each do |offer|
      # don't generate UDID reports for the Groupon offers that are whitelisted to TTR4
      next if offer.id == '853874a4-de66-4c00-b2bd-d51f456736f1' || offer.id == '17694838-2caa-4869-8808-0baf126daef9'

      stats = Appstats.new(offer.id, { :start_time => start_time, :end_time => end_time, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      if stats['paid_installs'].sum > 0
        message = { :offer_id => offer.id, :date => date_str }.to_json
        Sqs.send_message(QueueNames::UDID_REPORTS, message)
      end
    end
  end

  def self.generate_report(offer_id, date_str)
    date = Time.zone.parse(date_str).beginning_of_day
    conditions = "offer_id = '#{offer_id}' AND created >= '#{date.to_i}' AND created < '#{(date + 1.day).to_i}'"
    fs_path = "tmp/#{offer_id}_#{date.strftime('%Y-%m-%d')}.s3"
    outfile = File.open(fs_path, 'w')

    NUM_REWARD_DOMAINS.times do |i|
      Reward.select(:domain_name => "rewards_#{i}", :where => conditions) do |reward|
        if reward.udid?
          line = "#{reward.udid},#{reward.created.to_s(:db)},#{reward.country}"
          outfile.puts(line)
        end
      end
    end

    if outfile.pos > 0
      outfile.close
      path   = "#{offer_id}/#{date.strftime('%Y-%m')}/#{date.strftime('%Y-%m-%d')}.csv"
      bucket = AWS::S3.new.buckets[BucketNames::UDID_REPORTS]
      bucket.objects[path].write(:file => fs_path, :acl => :authenticated_read)
      cache_available_months(offer_id)
    end

  ensure
    outfile.close rescue nil
    File.delete(fs_path) rescue nil
  end

  def self.cache_available_months(offer_id)
    bucket = AWS::S3.new.buckets[BucketNames::UDID_REPORTS]
    months = Set.new
    bucket.objects.with_prefix("#{offer_id}/").each do |obj|
      next unless obj.key.ends_with?('.csv')
      month = obj.key.gsub("#{offer_id}/", '')[0...7]
      months << month
    end
    available_months = months.sort
    Mc.put("s3.udid_reports.#{offer_id}", available_months)
    available_months
  end

  def self.get_available_months(offer_id)
    Mc.get("s3.udid_reports.#{offer_id}") do
      cache_available_months(offer_id)
    end
  end

  def self.get_monthly_report(offer_id, month)
    bucket = AWS::S3.new.buckets[BucketNames::UDID_REPORTS]
    report_data = ''
    bucket.objects.with_prefix("#{offer_id}/#{month}/").each do |obj|
      report_data += obj.read
    end
    report_data
  end

  def self.get_daily_report(offer_id, date)
    bucket = AWS::S3.new.buckets[BucketNames::UDID_REPORTS]
    obj = bucket.objects["#{offer_id}/#{date[0...7]}/#{date}.csv"]
    if obj.exists?
      obj.read
    else
      ''
    end
  end

end
