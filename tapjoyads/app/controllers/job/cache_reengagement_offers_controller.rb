class Job::CacheReengagementOffersController < Job::JobController

  def index
    app_id_list = ReengagementOffer.active.find(:all, :select => 'DISTINCT app_id').map(&:app_id)
    app_id_list.each do |app_id|
      ReengagementOffer.cache_list app_id
  end
end
