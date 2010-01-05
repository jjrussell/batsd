class Job::MasterRewardAggregatorController < Job::JobController
  include RightAws
  
  def index
    time = Time.now.utc - 1.hour
    min_time = Time.utc(time.year, time.month, time.day, time.hour, 0, 0, 0)
    max_time = min_time + 1.hour
    
    msg = { 'start_hour' => min_time.to_f.to_s, 'last_hour' => max_time.to_f.to_s }.to_json
    SqsGen2.new.queue(QueueNames::REWARD_AGGREGATOR).send_message(msg)
    
    render :text => 'ok'
  end
  
end