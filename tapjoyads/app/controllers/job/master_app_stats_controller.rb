class Job::MasterAppStatsController < Job::JobController
  include SqsHelper
  
  def initialize
    @now = Time.now.utc
  end
  
  def index
    App.select(:where => "next_run_time < '#{@now.to_f.to_s}'", 
        :order_by => "next_run_time asc") do |app|
      message = {:app_key => app.key, :last_run_time => app.get('last_run_time')}.to_json

      # Set next_run_time here to make sure that it doesn't get picked up next run.
      # It will get set to a more accurate value in the queue_app_stats reader.
      app.put('next_run_time', @now.to_f + 1.hour)
      app.save
      
      send_to_sqs(QueueNames::APP_STATS, message)
    end
    
    render :text => 'ok'
  end
end