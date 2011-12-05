class Job::MasterCacheRecommendationsController < Job::JobController
  def index
    RecommendationList.cache_all

    render :text => 'ok'
  end

end
