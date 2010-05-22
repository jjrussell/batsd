class Job::QueueVerificationsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::VERIFICATIONS
  end
  
private
  
  def on_message(message)
    check_partner_balances
  end
  
  def check_partner_balances
    Partner.find_each do |partner|
      partner.recalculate_balances(false, true)
    end
  end
  
end
