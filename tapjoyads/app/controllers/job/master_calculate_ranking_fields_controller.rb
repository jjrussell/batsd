class Job::MasterCalculateRankingFieldsController < Job::JobController
  
  def index
    Offer.enabled_offers.find_each(&:calculate_ranking_fields!)
    render :text => 'ok'
  end
  
end
