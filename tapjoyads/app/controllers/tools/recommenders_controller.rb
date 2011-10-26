class Tools::RecommendersController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  
  def index
    @recommenders = Recommender::ACTIVE_RECOMMENDERS
    unless params[:recommender].blank?
      @recommender = "Recommenders::#{params[:recommender].to_s.camelize}".constantize.instance
      @options = {}
      n = params[:n].blank? ? 20 : params[:n].to_i
      @options[:with_weights] = !params[:with_weights].blank?
      if params[:app_or_device_id].blank?
        @recommendations_header = "Most Popular Apps: (Enter an app id or a device id for specific recommendations)"
        @recommendations = @recommender.most_popular_apps :n => n
      elsif params[:recommend_for]=='udid'
        @recommendations_header = "Recommendations for Device #{params[:app_or_device_id]}"
        @recommendations = @recommender.recommendations_for_udid params[:app_or_device_id], :n => n
      else
        @recommendations_header = "Recommendations for #{@recommender.app_name(params[:app_or_device_id])} (#{params[:app_or_device_id]})"
        @recommendations = @recommender.recommendations_for_app params[:app_or_device_id], :n => n
      end
    end
    respond_to do |format|
      format.html do
      end
      format.json do
        render :json => @recommendations.to_json
      end
    end
  end
  
  def create
    redirect_to params.merge!(:action => :index)
  end

end