class Job::QueueVerificationsController < Job::SqsReaderController
  include NewRelicHelper
  
  def initialize
    super QueueNames::VERIFICATIONS
  end
  
private
  
  def on_message(message)
    check_partner_balances
  end
  
  def check_partner_balances
    Partner.find_each do |partner|
      balance = partner.balance
      pending_earnings = partner.pending_earnings
      
      partner.recalculate_balances(true)
      
      if balance != partner.balance
        alert_new_relic(BalancesMismatch, "Balance mismatch for partner: #{partner.id}, previously: #{balance}, now: #{partner.balance}", request, params)
      end
      if pending_earnings != partner.pending_earnings
        alert_new_relic(BalancesMismatch, "Pending Earnings mismatch for partner: #{partner.id}, previously: #{pending_earnings}, now: #{partner.pending_earnings}", request, params)
      end
    end
  end
  
end
