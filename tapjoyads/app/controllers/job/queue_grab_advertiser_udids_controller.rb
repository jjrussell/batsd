class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

private

  # message = { :offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i }
  def on_message(message)
    json = JSON.load(message.to_s)
    offer_id = json["offer_id"]
    start_time = json["start_time"]
    finish_time = json["finish_time"]
    conditions = [
      "offer_id = '#{offer_id}'",
      "created >= '#{start_time}'",
      "created < '#{finish_time}'"].join(" and ")
    # TO REMOVE
    conditions = [
      "advertiser_app_id = '#{offer_id}'",
      "created >= '#{start_time}'",
      "created < '#{finish_time}'"].join(" and ")

    log = GrabAdvertiserUdidsLog.new(:key => "#{offer_id}.#{start_time}.#{finish_time}")
    return if log.job_finished_at?

    expected_attr = { 'job_started_at' => log.job_started_at? ? log.job_started_at.to_f.to_s : nil }

    log.offer_id = offer_id
    log.start_time = start_time
    log.finish_time = finish_time
    log.job_started_at = Time.zone.now
    begin
      log.save!(:expected_attr => expected_attr)
    rescue ExpectedAttributeError => e
      return
    end

    message.delete

    bucket = S3.bucket(BucketNames::AD_UDIDS)
    path = Offer.s3_udids_path(offer_id, Time.zone.at(start_time))
    fs_path = "tmp/#{path.gsub('/', '_')}.s3"
    write_to_s3 = false
    data = File.open(fs_path, 'w+')
    if bucket.key(path).exists?
      data.write(bucket.get(path))
    end

    Reward.select(:where => conditions) do |reward|
      unless reward.udid.blank?
        line = "#{reward.udid},#{reward.created.to_s(:db)}"
        data.puts(line)
        write_to_s3 = true
      end
    end

    if write_to_s3
      retries = 3
      begin
        data.rewind
        bucket.put(path, data.read, {}, 'authenticated-read')
      rescue RightAws::AwsError => e
        if retries > 0 && e.message =~ /^RequestTimeTooSkewed/
          retries -= 1
          retry
        else
          raise e
        end
      end
    end

    log.job_finished_at = Time.zone.now
    log.save

  ensure
    data.close rescue nil
    File.delete(fs_path) rescue nil
  end
end
