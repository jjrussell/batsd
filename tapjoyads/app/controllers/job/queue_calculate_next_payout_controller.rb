class Job::QueueCalculateNextPayoutController < Job::SqsReaderController
  include NewRelicHelper
  
  def initialize
    super QueueNames::CALCULATE_NEXT_PAYOUT
  end
  
  private
  
  def on_message(message)
    today = Time.zone.now
    yesterday = today - 1.day
    
    Partner.to_calculate_next_payout_amount.each do |partner|
      # store the cutoff dates and current next payout amount for error checking
      today_cutoff_date = partner.payout_cutoff_date(today)
      yesterday_cutoff_date = partner.payout_cutoff_date(yesterday)
      current_next_payout_amount = partner.next_payout_amount
      
      # calculate the next payout amount inside a transaction and reload the object first to ensure consistency
      Partner.transaction do
        partner.reload.calculate_next_payout_amount
        partner.save!
      end
      
      # verify that nothing changed if the cutoff date is the same
      if today_cutoff_date == yesterday_cutoff_date && current_next_payout_amount != partner.next_payout_amount
        alert_new_relic(CalculateNextPayoutMismatch, "next_payout_amount differs for partner: #{partner.id}, previously: #{current_next_payout_amount}, now: #{partner.next_payout_amount}", request, params)
      end
    end
  end
  
end
