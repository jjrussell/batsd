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
      recipients = partner.non_managers.reject { |user| !user.receive_campaign_emails? }.collect(&:email).reject { |email| email.blank? }
      unless recipients.empty?
        low_balance = offers_needing_more_funds.present?
        account_balance = partner.balance
        account_manager = partner.account_managers.first
        account_manager_email = account_manager ? account_manager.email : nil
        premier = partner.is_premier?
        premier_discount = partner.premier_discount
        TapjoyMailer.deliver_campaign_status(recipients, partner, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
      end
    end
  end

end
