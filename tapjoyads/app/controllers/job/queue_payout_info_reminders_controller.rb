class Job::QueuePayoutInfoRemindersController < Job::SqsReaderController

  def initialize
    super QueueNames::PAYOUT_INFO_REMINDERS
  end

  private

  def on_message(message)
    json = JSON.load(message.to_s)
    partner_id = json["partner_id"]
    partner = Partner.find partner_id
    return unless partner.balance > 0

    recipients = partner.non_managers.select(&:receive_campaign_emails?).map(&:email).reject(&:blank?)
    unless recipients.empty? && Rails.env != 'production'
      TapjoyMailer.deliver_payout_info_reminder(recipients, partner.pending_earnings)
    end
  end
end

