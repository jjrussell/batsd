class Tools::RecommendersController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  def index
    @recommenders = Recommender::ACTIVE_RECOMMENDERS
    @options = { :with_weights => (params[:with_weights] == 'true') }
    unless params[:recommender].blank?
      recommender = "Recommenders::#{params[:recommender].to_s.camelize}".constantize.instance
      n = params[:n].blank? ? 20 : params[:n].to_i
      @options[:recommender] = recommender.type
      case
      when params[:recommend_for] == 'udid' && !params[:app_or_device_id].blank?
        @options[:description] = "Recommendations for Device #{params[:app_or_device_id]} by #{@recommenders[recommender.type]}"
        @options[:udid] = params[:app_or_device_id]
        @recommendations = recommender.recommendations_for_udid params[:app_or_device_id], :n => n
      when params[:recommend_for] == 'app_id' && !params[:app_or_device_id].blank?
        @options[:description] = "Recommendations for App #{recommender.app_name(params[:app_or_device_id])} (#{params[:app_or_device_id]})  by #{@recommenders[recommender.type]}"
        @options[:app_id] = params[:app_or_device_id]
        @options[:app_name] = recommender.app_name(params[:app_or_device_id])
        @recommendations = recommender.recommendations_for_app params[:app_or_device_id], :n => n
      else
        @options[:description] = "Most Popular Apps (Enter an app id or a device id for specific recommendations)"
        @recommendations = recommender.most_popular_apps :n => n
      end
    end

    respond_to do |format|
      format.html do
      end
      format.json do
        render :json => {
          :options => @options,
          :recommendations => @recommendations
        }
      end
    end
  end

  def create
    redirect_to params.merge!(:action => :index)
  end
end
