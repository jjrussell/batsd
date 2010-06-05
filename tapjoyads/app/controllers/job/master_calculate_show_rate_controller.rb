##
# Sends one app_key to the queue for each app that should have its show_rate calculated.
class Job::MasterCalculateShowRateController < Job::JobController
  include SqsHelper
  
  def index
    where_clause = "install_tracking = '1' and payment_for_install > '0' and balance > '0' and itemName() is not null"
    
    count = SdbApp.count(:where => where_clause)
    
    SdbApp.select(:attributes => 'itemName()', :where => where_clause, :order_by => "itemName()") do |app|
      
      time = Benchmark.realtime { send_to_sqs(QueueNames::CALCULATE_SHOW_RATE, app.key) }
      
      sleep((20.minutes.to_f / count) - time)
    end
    
    render :text => 'ok'
  end
end