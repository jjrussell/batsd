class Job::MasterCalculateRankingFieldsController < Job::JobController

  def index
    Offer.enabled_offers.updated_before(30.minutes.ago).find_each(&:calculate_ranking_fields!)
    render :text => 'ok'
  end

end
