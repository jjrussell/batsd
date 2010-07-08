class Job::MasterCleanupStoreClickController < Job::JobController
  def index
    time = Time.zone.now.beginning_of_day - 40.days
    10.times do
      count = StoreClick.count(:where => "click_date >= '#{time.to_i}' and click_date < '#{(time + 24.hours).to_i}'")
      if count > 0
        Sqs.send_message(QueueNames::CLEANUP_STORE_CLICK, time.to_date.to_s(:db))
      end
      time += 1.day
    end
    
    render :text => 'ok'
  end
end