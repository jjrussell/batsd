class Job::QueueCalculateNextPayoutController < Job::SqsReaderController
  include NewRelicHelper
  
  def initialize
    super QueueNames::CALCULATE_NEXT_PAYOUT
  end
  
  private
  
  def on_message(message)
    Partner.to_calculate_next_payout_amount.each do |partner|
      partner.calculate_next_payout_amount(true)
    end
  end
  
end
