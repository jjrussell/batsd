class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day

    Offer.find_each do |offer|
      message = [offer.id, today.to_i].to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)

      # check if previous day's job failed
      unless bucket.key(App.udid_s3_key(offer.id, yesterday)).exists?
        message = [offer.id, yesterday.to_i].to_json
        Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      end

      sleep(2) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
