class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

  private

  # message = app_id[:yyyy-mm-dd]
  def on_message(message)
    message.delete
    messages = message.to_s.split(':')
    @advertiser_app_id = messages[0]

    if messages[1] # date was hard-coded
      date = Time.zone.parse(messages[1]) rescue Time.zone.now
      save_udids(@advertiser_app_id, date)
    else
      # this month, up to now
      date = Time.zone.now
      not_empty = save_udids(@advertiser_app_id, date)

      # finalize last month, if necessary
      path = App.udid_s3_key(@advertiser_app_id, date)
      previous_path = bucket.get("latest/#{@advertiser_app_id}") rescue nil
      if path != previous_path
        save_udids(@advertiser_app_id, 1.month.ago(date))
      end

      # update latest to current path, unless empty
      bucket.put("latest/#{@advertiser_app_id}", path) if not_empty
    end
  end

  def save_udids(app_id, date)
    path = App.udid_s3_key(app_id, date)
    first_day = date.beginning_of_month
    last_day = 1.month.since(first_day) # first day of next month
    conditions = ["udid is not null",
      "advertiser_app_id = '#{app_id}'",
      "created >= '#{first_day.to_f}'",
      "created < '#{last_day.to_f}'"].join(" and ")

    udids = []
    Reward.select(:where => conditions) do |reward|
      udids << [reward.get("udid"), reward.get("created")].join(",")
    end
    udids = udids.compact.uniq
    bucket.put(path, udids.join("\n"), {}, 'authenticated-read') unless udids.blank?
    return !udids.blank?
  end

  # avoid RequestTimeTooSkewed in save_udids by refreshing it each time
  def bucket
    S3.bucket(BucketNames::AD_UDIDS)
  end
end
