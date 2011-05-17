class Job::MasterCacheOffersController < Job::JobController
  
  def index
    Offer.enabled_offers.each do |offer|
      if offer.partner.balance <= 10000 && offer.is_free?
        new_show_rate = [ 0.10, offer.show_rate ].min
        next if offer.show_rate == new_show_rate
        
        # lookup the offer again because the named_scope returns offer as read-only
        offer_to_update = Offer.find(offer.id)
        offer_to_update.show_rate = new_show_rate
        offer_to_update.save(false)
      end
    end
    
    S3.reset_connection
    
    Offer.cache_offer_stats
    Offer.cache_offers
    
    Currency.all.collect(&:id).each do |currency_id|
      Sqs.send_message(QueueNames::CACHE_OFFERS, currency_id)
    end
    
    render :text => 'ok'
  end
  
end
