class Job::QueuePartnerNotificationsController < Job::SqsReaderController

  def initialize
    super QueueNames::PARTNER_NOTIFICATIONS
  end

  private

  def on_message(message)
    json = JSON.load(message.body)
    partner_id = json["partner_id"]
    partner = Partner.find partner_id
    offers = partner.offers.enabled_offers
    return if offers.empty?
    offers_needing_more_funds = []
    offers_needing_higher_bids = []
    offers_not_meeting_budget = []

    offers.each do |offer|
      if offer.needs_more_funds?
        offers_needing_more_funds << offer if offer.payment < partner.balance
      end
    end

    unless offers_needing_more_funds.empty? && offers_needing_higher_bids.empty? && offers_not_meeting_budget.empty?
      recipients = partner.users.select { |user| user.receive_campaign_emails? && user.can_email && !user.email.blank? }.collect(&:email)
      sales_rep = partner.sales_rep
      recipients << sales_rep.email if sales_rep.present? && sales_rep.email.present?
      unless recipients.empty?
        low_balance = offers_needing_more_funds.present?
        account_balance = partner.balance
        account_manager = partner.account_managers.first
        account_manager_email = account_manager ? account_manager.email : nil
        premier = partner.is_premier?
        premier_discount = partner.premier_discount
        begin
          TapjoyMailer.deliver_campaign_status(recipients, partner, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
        rescue AWS::SimpleEmailService::Errors::MessageRejected => e
          if e.to_s =~ /Address blacklisted/
            raise e.inspect + recipients.inspect
          else
            raise e
          end
        end
      end
    end
  end

end
