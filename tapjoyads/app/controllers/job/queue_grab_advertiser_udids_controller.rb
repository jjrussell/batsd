class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

  private

  # message = [ app_id, date, period ]
  def on_message(message)
    messages = JSON.load(message.to_s)
    app_id = messages[0]
    today = Time.zone.at(messages[1])
    @type = messages[2] || "daily"
    @bucket = S3.bucket(BucketNames::AD_UDIDS)

    save_udids(app_id, today)
  end

  def save_udids(app_id, date)
    path = App.udid_s3_key(app_id, date)
    if @type == "monthly"
      path = path[0..-4] # drop -01
      day_in_the_past = 1.month.ago(date)
    else
      day_in_the_past = 1.day.ago(date)

      # check if previous day's job failed
      previous_path = App.udid_s3_key(app_id, day_in_the_past)
      unless @bucket.key(previous_path).exists?
        # push this to queue
        message = [app_id, day_in_the_past.to_i].to_json
        Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      end
    end

    return if @bucket.key(path).exists? # don't overwrite
    conditions = [
      "advertiser_app_id = '#{app_id}'",
      "created >= '#{day_in_the_past.to_f}'",
      "created < '#{date.to_f}'"].join(" and ")

    udids = []
    Reward.select(:where => conditions) do |reward|
      udids << [reward.get("udid"), reward.get("created")].join(",")
    end
    udids = udids.compact.uniq
    @bucket.put(path, udids.join("\n"), {}, 'authenticated-read')
  end
end
