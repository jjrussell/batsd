class Job::MasterGrabDisabledPopularOffersController < Job::JobController
  def initialize
  end

  def index
    now = Time.zone.now
    offers = {}
    Offer.find_each(:conditions => {:tapjoy_enabled => false}) do |offer|
      options = { :start_time => now.beginning_of_hour - 23.hours, :end_time => now, :stat_types => ['daily_active_users'] }
      sum = Appstats.new(offer.id, options).stats['daily_active_users'].sum
      offers[offer.id] = sum if sum > 5
    end

    Mc.distributed_put('tools.disabled_popular_offers', offers)

    render :text => 'ok'
  end
end
