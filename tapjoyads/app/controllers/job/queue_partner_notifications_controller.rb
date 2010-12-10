class Job::QueuePartnerNotificationsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::PARTNER_NOTIFICATIONS
  end
  
  private
  
  def on_message(message)
    json = JSON.load(message.to_s)
    partner_id = json["partner_id"]
    partner = Partner.find partner_id
    offers = partner.offers.enabled_offers
    return if offers.empty?
    offers_needing_more_funds = []
    offers_needing_higher_bids = []
    offers_not_meeting_budget = []
    
    offers.each do |offer|
      if offer.needs_more_funds?
        offers_needing_more_funds << offer
      elsif offer.budget_may_not_be_met?
        offers_not_meeting_budget << offer
      elsif offer.needs_higher_bid?
        offers_needing_higher_bids << offer
      end
    end
    
    if !offers_needing_more_funds.empty? || !offers_needing_higher_bids.empty? || !offers_not_meeting_budget.empty?
      recipients = partner.non_managers.reject { |user| !user.receive_campaign_emails }.collect(&:email).reject { |email| email.blank? }
      unless recipients.empty?
        low_balance = !offers_needing_more_funds.empty?
        account_balance = partner.balance
        account_manager = partner.account_managers.first
        account_manager_email = account_manager ? account_manager.email : nil
        premier = partner.is_premier?
        premier_discount = partner.premier_discount
        TapjoyMailer.deliver_campaign_status(recipients, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
      end
    end
  end
end