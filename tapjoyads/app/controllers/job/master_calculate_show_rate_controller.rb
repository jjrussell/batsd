##
# Sends one app_key to the queue for each app that should have its show_rate calculated.
class Job::MasterCalculateShowRateController < Job::JobController
  def index
    queue = RightAws::SqsGen2.new.queue(QueueNames::CALCULATE_SHOW_RATE)
    
    App.select(:attributes => 'itemName()', 
        :where => "install_tracking = '1' and payment_for_install > '0'") do |app|
      
      queue.send_message(app.key)
      
    end
    
    render :text => 'ok'
  end
end