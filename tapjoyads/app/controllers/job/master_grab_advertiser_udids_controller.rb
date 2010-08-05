class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day

    Offer.find_each do |offer|
      message = {:offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i}
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message.to_json)

      sleep(2) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
