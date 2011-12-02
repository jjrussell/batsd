class Job::MasterUpdateAppsPapayaTotalUserController < Job::JobController
  def index
    Papaya.update_apps
    OfferCacher.cache_papaya_offers
    render :text => 'ok'
  end
end
