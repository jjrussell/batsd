class Job::MasterCacheOffersController < Job::JobController

  def index
    Offer.enabled_offers.find_each do |offer|
      offer.update_attribute(:show_rate, 0.10) if offer.is_free? && offer.show_rate > 0.10 && offer.partner.balance <= 10000 && !offer.allow_negative_balance
    end

    OfferCacher.cache_offer_stats
    OfferCacher.cache_offers(Time.now.min == 0)

    render :text => 'ok'
  end

end
