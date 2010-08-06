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
      "advertiser_app_id = '#{offer_id}'",
      "created >= '#{start_time}'",
      "created < '#{finish_time}'"].join(" and ")

    bucket = S3.bucket(BucketNames::AD_UDIDS)
    path = App.udid_s3_key(offer_id, Time.zone.at(start_time))

    data = ''
    do_regex_check = true
    if bucket.key(path).exists?
      data = bucket.get(path)
    end

    Reward.select(:where => conditions) do |reward|
      unless reward.udid.blank?
        line = "#{reward.udid},#{reward.created.to_s(:db)}"
        if do_regex_check
          if data =~ /#{line}/
            return
          else
            do_regex_check = false
          end
        end
        data += line + "\n"
      end
    end

    bucket.put(path, data, {}, 'authenticated-read') unless data.blank?
  end
end
