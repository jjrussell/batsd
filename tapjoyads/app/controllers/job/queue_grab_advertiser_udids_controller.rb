class Job::QueueGrabAdvertiserUdidsController < Job::SqsReaderController

  def initialize
    super QueueNames::GRAB_ADVERTISER_UDIDS
  end

  private

  def on_message(message)
    @advertiser_app_id = message.to_s
    @bucket = RightAws::S3.new.bucket('ad-udids')

    # this month, up to now
    date = Time.zone.now
    save_uuids(date)

    # finalize last month, if necessary
    path = "udids/#{date.strftime("%Y-%m")}/#{@advertiser_app_id}"
    previous_path = @bucket.get("latest/#{@advertiser_app_id}") rescue nil
    if path != previous_path
      save_uuids(1.month.ago(date))
    end

    # update latest to current path
    @bucket.put("latest/#{@advertiser_app_id}", path)

    # getting udid file given advertiser_id
    # path = bucket.get("latest/#{app_id}") rescue nil
    # udids = path ? bucket.get(path) : ""
  end

  def save_uuids(date)
    path = "udids/#{date.strftime("%Y-%m")}/#{@advertiser_app_id}"
    first_day = Time.zone.parse("#{date.strftime("%Y-%m")}-01")
    last_day = 1.day.ago(1.month.since(first_day))
    conditions = ["udid is not null",
      "advertiser_app_id = '#{@advertiser_app_id}'",
      "created > '#{first_day.to_f}'",
      "created < '#{last_day.to_f}'"].join(" and ")

    udids = []
    Reward.select(:where => conditions) do |reward|
      udids << reward.get("udid")
    end
    @bucket.put(path, udids.compact.uniq.join("\n"))
  end
end
