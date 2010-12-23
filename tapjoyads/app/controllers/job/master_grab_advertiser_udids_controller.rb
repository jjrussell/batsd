class Job::MasterGrabAdvertiserUdidsController < Job::JobController
  def index
    today = Time.zone.now.beginning_of_day
    yesterday = today - 1.day

    Offer.find_each do |offer|
      # don't generate UDID reports for the Groupon offers that are whitelisted to TTR4
      next if offer.id == '853874a4-de66-4c00-b2bd-d51f456736f1' || offer.id == 'ba3e4880-8903-4703-ba1d-790a86060058'

      stats = Appstats.new(offer.id, { :start_time => yesterday, :end_time => today, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      next unless stats['paid_installs'].sum > 0

      message = { :offer_id => offer.id, :start_time => yesterday.to_i, :finish_time => today.to_i }.to_json
      Sqs.send_message(QueueNames::GRAB_ADVERTISER_UDIDS, message)

      sleep(3)
    end

    render :text => 'ok'
  end
end
