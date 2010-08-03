class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    # yesterday
    date = Time.zone.now.beginning_of_day.to_i
    Offer.find_each do |offer|
      message = [offer.id, date].to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
      sleep(2) #don't want to overwhelm the job servers
    end

    render :text => 'ok'
  end
end
