class Job::MasterAppStatsController < Job::JobController
  
  def initialize
    @now = Time.now.utc
  end
  
  def index
    apps =  SimpledbResource.select('app', '*', 
        "next_run_time < '#{@now.to_f.to_s}'", "next_run_time asc").items
    
    apps.each do |app|
      message = {:app_key => app.key}.to_json
      
      SqsGen2.new.queue(QueueNames::APP_STATS).send_message(message)
    end
    
    render :text => 'ok'
  end
end