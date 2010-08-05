class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

  private

  # message = {:offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i}
  def on_message(message)
    messages = JSON.load(message.to_s)
    offer_id = messages["offer_id"]
    start_time = messages["start_time"].to_i
    finish_time = messages["finish_time"].to_i
    conditions = [
      "advertiser_app_id = '#{offer_id}'",
      "created >= '#{start_time}'",
      "created < '#{finish_time}'"].join(" and ")

    bucket = S3.bucket(BucketNames::AD_UDIDS)
    path = App.udid_s3_key(offer_id, Time.zone.at(start_time))

    data = nil
    first_new_timestamp = nil
    Reward.select(:where => conditions) do |reward|
      unless reward.get('udid').blank?
        first_new_timestamp ||= reward.get('created') # just the first one
        line = [ reward.get('udid'), reward.get('created') ].join(",")
        data = data.nil? ? line : [ data, line ].join("\n")
      end
    end

    if bucket.key(path).exists?
      old_data = bucket.get(bucket.key(path))
      last_line = old_data.split(/\n/).last
      last_old_timestamp = last_line.split(/,/).last.to_f
      if last_old_timestamp <= first_new_timestamp
        # good: combine old data with current data
        new_data = [old_data, data].join("\n")
        bucket.put(path, new_data, {}, 'authenticated-read') unless data.blank?
      else
        # bad: store to failed_save directory
        new_path = "failed_save/#{offer_id}/#{Time.zone.at(start_time).strftime("%Y-%m-%d")}"
        bucket.put(new_path, data, {}, 'authenticated-read') unless data.blank?
      end
    end

  end
end
