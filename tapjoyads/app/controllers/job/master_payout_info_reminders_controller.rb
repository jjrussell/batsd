# don't run this until Mary et al go through existing W8/W9 forms
class Job::MasterPayoutInfoRemindersController < Job::JobController
  def index
    Partner.to_payout.each do |partner|
      unless partner.completed_payout_info? && partner.pending_earnings >= 25000
        recipients = partner.non_managers.select(&:receive_campaign_emails?).map(&:email).reject(&:blank?)
        unless recipients.empty? && !Rails.env.production?
          TapjoyMailer.deliver_payout_info_reminder(recipients, partner.pending_earnings)
          sleep 2
        end
      end
    end
    render :text => 'ok'
  end
end
