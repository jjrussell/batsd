##
# Sends one app_key to the queue for each app that should have its show_rate calculated.
class Job::MasterCalculateShowRateController < Job::JobController
  include SqsHelper
  
  def index
    offers = Offer.enabled_offers
    count = offers.length
    
    offers.each do |offer|
      time = Benchmark.realtime { send_to_sqs(QueueNames::CALCULATE_SHOW_RATE, offer.id) }
      sleep((20.minutes.to_f / count) - time)
    end
    
    render :text => 'ok'
  end
end
