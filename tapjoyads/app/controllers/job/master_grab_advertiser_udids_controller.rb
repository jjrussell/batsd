class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day

    Offer.find_each do |offer|
      message = { :offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)

      sleep(2)
    end

    render :text => 'ok'
  end
end
