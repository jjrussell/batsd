class Tools::RecommendersController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  
  def index
    @recommenders = Recommender::ACTIVE_RECOMMENDERS
    unless params[:recommender].blank?
      @recommender = "Recommenders::#{params[:recommender].to_s.camelize}".constantize.instance
      @recs_for_app = @recommender.recommendations_for_app(params[:app_id], :n=>20, :with_weights => true) unless params[:app_id].blank?
      @recs_for_udid = @recommender.recommendations_for_udid(params[:udid], :n=>20, :with_weights => true) unless params[:udid].blank?
    end
  end
  
  def create
    # redirect_to tools_recommenders_path(params)
    redirect_to tools_recommenders_path :recommender => params[:recommender], :app_id => params[:app_id], :udid => params[:udid]
  end

end