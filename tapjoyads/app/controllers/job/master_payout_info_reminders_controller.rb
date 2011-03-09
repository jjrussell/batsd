# don't run this until Mary et al go through existing W8/W9 forms
class Job::MasterPayoutInfoRemindersController < Job::JobController
  def index
    Partner.to_payout.each do |partner|
      unless partner.completed_payout_info? && partner.pending_earnings >= 25000
        Sqs.send_message(QueueNames::PAYOUT_INFO_REMINDERS, { :partner_id => partner_id }.to_json)
      end
    end
    render :text => 'ok'
  end
end
