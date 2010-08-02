class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index

    Offer.find_each do |offer|
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, offer.id)
      sleep(2) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
