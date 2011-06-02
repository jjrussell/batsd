class Job::MasterUdidReportsController < Job::JobController
  
  def index
    start_time = Time.zone.now.beginning_of_day - 1.day
    end_time   = start_time + 1.day
    date_str   = start_time.strftime('%Y-%m-%d')
    
    Offer.find_each do |offer|
      # don't generate UDID reports for the Groupon offers that are whitelisted to TTR4
      next if offer.id == '853874a4-de66-4c00-b2bd-d51f456736f1' || offer.id == '17694838-2caa-4869-8808-0baf126daef9'
      
      stats = Appstats.new(offer.id, { :start_time => start_time, :end_time => end_time, :granularity => :hourly, :stat_types => [ 'paid_installs' ] }).stats
      if stats['paid_installs'].sum > 0
        message = { :offer_id => offer.id, :date => date_str }.to_json
        Sqs.send_message(QueueNames::UDID_REPORTS, message)
      end
    end
    
    render :text => 'ok'
  end
  
end
