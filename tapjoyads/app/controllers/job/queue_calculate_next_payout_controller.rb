class Job::QueueCalculateNextPayoutController < Job::SqsReaderController

  def initialize
    super QueueNames::CALCULATE_NEXT_PAYOUT
  end

  private

  def on_message(message)
    Partner.to_calculate_next_payout_amount.each do |partner|
      Partner.transaction do
        partner.reload.calculate_next_payout_amount
        partner.save!
      end
    end
  end
  
end