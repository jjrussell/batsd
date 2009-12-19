class Job::MasterAppStatsController < Job::JobController
  include RightAws
  
  def initialize
    @now = Time.now.utc
  end
  
  def index
    apps =  SimpledbResource.select('app', '*', 
        "next_run_time < '#{@now.to_f.to_s}'", "next_run_time asc").items
    
    apps.each do |app|
      message = {:app_key => app.key, :last_run_time => app.get('last_run_time')}.to_json

      # Set next_run_time here to make sure that it doesn't get picked up next run.
      # It will get set to a more accurate value in the queue_app_stats reader.
      app.put('next_run_time', app.get('next_run_time').to_f + 1.hour)
      app.save
      
      SqsGen2.new.queue(QueueNames::APP_STATS).send_message(message)
    end
    
    render :text => 'ok'
  end
end