class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    @bucket = S3.bucket(BucketNames::AD_UDIDS)
    # yesterday
    date = Time.zone.now.beginning_of_day.to_i
    previous_day = 1.day.ago(date)
    Offer.find_each do |offer|
      message = [offer.id, date].to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)

      # check if previous day's job failed
      unless @bucket.key(App.udid_s3_key(app_id, previous_day)).exists?
        message = [app_id, day_in_the_past.to_i].to_json
        Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      end

      sleep(2) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
