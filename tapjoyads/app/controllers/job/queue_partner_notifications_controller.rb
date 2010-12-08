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
    
    offers.each do |offer|
      if offer.needs_more_funds?
        offers_needing_more_funds << offer
      elsif offer.needs_higher_bid?
        offers_needing_higher_bids << offer
      end
    end
    
    if !offers_needing_more_funds.empty? || !offers_needing_higher_bids.empty?
      # replace with email
      logger.info "Spamming #{partner.name}"
      logger.info "  - more funds: #{offers_needing_more_funds.collect(&:name).join(',')}" if !offers_needing_more_funds.empty?
      logger.info "  - higher bids: #{offers_needing_higher_bids.collect(&:name).join(',')}" if !offers_needing_higher_bids.empty?
    end
  end
end