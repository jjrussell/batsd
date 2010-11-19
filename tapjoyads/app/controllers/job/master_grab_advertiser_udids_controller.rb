class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day

    Offer.find_each do |offer|
      stats = Appstats.new(offer.id, { :start_time => yesterday, :end_time => today, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      next unless stats['paid_installs'].sum > 0

      message = { :offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)

      sleep(3)
    end

    render :text => 'ok'
  end
end
