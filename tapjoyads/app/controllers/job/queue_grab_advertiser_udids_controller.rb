class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

  private

  # message = [ app_id, date, period ]
  def on_message(message)
    messages = JSON.load(message)
    app_id = messages[0]
    today = Time.zone.at(messages[1])
    @type = messages[2] || "daily"
    @bucket = S3.s3.bucket(BucketNames::AD_UDIDS)

    save_udids(app_id, today)
  end

  def save_udids(app_id, date)
    Rails.logger.info "prepare to grab udids for #{app_id} for #{date.strftime('%Y-%m-%d')}"

    path = App.udid_s3_key(app_id, date)
    day_in_the_past = 1.day.ago(date)
    if @type == "monthly"
      path = path[0..-4] # drop -01
      day_in_the_past = 1.month.ago(date)
    end

    return if @bucket.keys.map(&:names).include?(path) # don't overwrite
    conditions = [
      "advertiser_app_id = '#{app_id}'",
      "created >= '#{day_in_the_past.to_f}'",
      "created < '#{date.to_f}'"].join(" and ")

    udids = []
    Reward.select(:where => conditions) do |reward|
      udids << [reward.get("udid"), reward.get("created")].join(",")
    end
    udids = udids.compact.uniq
    @bucket.put(path, udids.join("\n"), {}, 'authenticated-read') unless udids.blank?

    Rails.logger.info "saved udids for #{app_id} for #{date.strftime('%Y-%m-%d')}"
  end
end
