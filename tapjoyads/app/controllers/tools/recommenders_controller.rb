class Tools::RecommendersController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  def index
    @recommenders = Recommender::ACTIVE_RECOMMENDERS
    @options = { :with_weights => (params[:with_weights] == 'true') }
    if params[:recommender].present?
      recommender = Recommender.instance params[:recommender]
      n = params[:n].blank? ? 20 : params[:n].to_i
      @options[:recommender] = recommender.type
      case
      when params[:recommend_for] == 'udid' && params[:app_or_device_id].present?
        @options[:description] = "Recommendations for Device #{params[:app_or_device_id]} by #{@recommenders[recommender.type]}"
        @options[:udid] = params[:app_or_device_id]
        @recommendations = recommender.for_device(params[:app_or_device_id], :n => n)
      when params[:recommend_for] == 'app_id' && params[:app_or_device_id].present?
        app = App.find(params[:app_or_device_id]) rescue nil
        app_name = app ? app.name : "No App found with id #{params[:app_or_device_id]}"
        @options[:description] = "Recommendations for App #{app_name} (#{params[:app_or_device_id]})  by #{@recommenders[recommender.type]}"
        @options[:app_id] = params[:app_or_device_id]
        @options[:app_name] = app_name
        @recommendations = recommender.for_app(params[:app_or_device_id], :n => n)
      else
        @options[:description] = "Most Popular Apps (Enter an app id or a device id for specific recommendations)"
        @recommendations = recommender.most_popular(:n => n)
      end
      @recommendations.map!{|app_id, weight| make_display_hash(app_id, weight)} if @recommendations
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

  private
  def make_display_hash(app_id, weight)
    offer = Offer.find(app_id) rescue nil
    {:app_id => app_id, :weight => weight, :app_name => offer.nil? ? "NO OFFER FOUND FOR THIS APP" : offer.name , :offer => offer}
  end
end
