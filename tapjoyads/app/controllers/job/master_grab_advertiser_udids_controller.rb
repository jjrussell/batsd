class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day
    day_before_yesterday = yesterday - 1.day

    Offer.find_each do |offer|
      message_sent = false
      # don't generate UDID reports for the Groupon offers that are whitelisted to TTR4
      next if offer.id == '853874a4-de66-4c00-b2bd-d51f456736f1' || offer.id == '17694838-2caa-4869-8808-0baf126daef9'

      stats = Appstats.new(offer.id, { :start_time => yesterday, :end_time => today, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      if stats['paid_installs'].sum > 0
        message = { :offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i }.to_json
        Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
        message_sent = true
      end

      stats = Appstats.new(offer.id, { :start_time => day_before_yesterday, :end_time => yesterday, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      if stats['paid_installs'].sum > 0 && GrabAdvertiserUdidsLog.find("#{offer.id}.#{day_before_yesterday.to_i}.#{yesterday.to_i}").nil?
        message = { :offer_id => offer.id, :start_time => day_before_yesterday.to_i, :finish_time => yesterday.to_i }.to_json
        Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)
        message_sent = true
      end
      
      sleep(3) if message_sent
    end

    render :text => 'ok'
  end
end
