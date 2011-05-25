class Job::MasterCalculateRankBoostsController < Job::JobController
  
  def index
    Offer.with_rank_boosts.each do |offer|
      offer.calculate_rank_boost!
    end
    
    render :text => 'ok'
  end
  
end
