class Job::MasterRunOfferEventsController < Job::JobController

  def index
    OfferEvent.to_run.each do |event|
      log_activity(event.offer)
      log_activity(event)
      event.run!
      save_activity_logs(true)
    end

    render :text => 'OK'
  end

end
