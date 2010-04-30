##
# Sends one app_key to the queue for each app that should have its show_rate calculated.
class Job::MasterCalculateShowRateController < Job::JobController
  include SqsHelper
  
  def index
    SdbApp.select(:attributes => 'itemName()', 
        :where => "install_tracking = '1' and payment_for_install > '0' and balance > '0' and itemName() is not null",
        :order_by => "itemName()") do |app|
      
      send_to_sqs(QueueNames::CALCULATE_SHOW_RATE, app.key)
      
      sleep(10)
    end
    
    render :text => 'ok'
  end
end