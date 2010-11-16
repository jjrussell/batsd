##
# Sends one app_key to the queue for each app that should have its show_rate calculated.
class Job::MasterCalculateShowRateController < Job::JobController
  def index
    offers = Offer.enabled_offers
    count = offers.length
    
    offers.each do |offer|
      next if offer.payment == 0
      
      time = Benchmark.realtime { Sqs.send_message(QueueNames::CALCULATE_SHOW_RATE, offer.id) }
      sleep((20.minutes.to_f / count) - time)
    end
    
    render :text => 'ok'
  end
end
