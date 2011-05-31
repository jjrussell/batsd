class Job::MasterCalculateRankBoostsController < Job::JobController
  
  def index
    Offer.with_rank_boosts.find_each do |offer|
      offer.calculate_rank_boost!
    end
    
    render :text => 'ok'
  end
  
end
