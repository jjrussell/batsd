class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    Offer.each do |offer|
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, advertiser.id)
      sleep(1) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
