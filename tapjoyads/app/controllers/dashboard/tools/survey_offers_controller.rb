class Dashboard::Tools::SurveyOffersController < Dashboard::DashboardController
  layout 'tabbed'

  current_tab :tools

  filter_access_to :all

  before_filter :find_survey_offer, :only => [ :edit, :update, :destroy, :toggle_enabled ]

  def index
    @survey_offers = SurveyOffer.visible
  end

  def new
    @survey_offer = SurveyOffer.new
  end

  def create
    sanitize_currency_params(params[:survey_offer], [ :bid ])
    questions_attrs = params[:survey_offer].delete(:questions_attributes)
    options = { :questions_attributes => questions_attrs }
    @survey_offer = SurveyOffer.new(params[:survey_offer])

    # accepts_attributes_for doesn't play nice with UuidPrimaryKey on creation
    if @survey_offer.save && @survey_offer.update_attributes(options)
      flash[:notice] = 'Survey offer created successfully'
      redirect_to tools_survey_offers_path
    else
      flash.now[:error] = 'Problems creating survey offer'
      redirect_to :action => :new
    end
  end

  def edit; end

  def update
    if @survey_offer.locked?
      flash[:error] = 'This survey is locked. Please create a new survey to make changes.'
      redirect_to tools_survey_offers_path and return
    end
    sanitize_currency_params(params[:survey_offer], [ :bid ])
    if @survey_offer.update_attributes(params[:survey_offer])
      flash[:notice] = 'Survey offer updated successfully'
      redirect_to tools_survey_offers_path
    else
      flash.now[:error] = 'Problems updating survey offer'
      render :action => :edit
    end
  end

  def destroy
    @survey_offer.hide!
    flash[:notice] = 'Survey offer removed successfully'
    redirect_to tools_survey_offers_path
  end

  def toggle_enabled
    @survey_offer.enabled? ? @survey_offer.disable! : @survey_offer.enable!
    if @survey_offer.save
      flash[:notice] = 'Survey offer updated.'
    else
      flash[:error] = 'Problems updating survey offer'
    end
    redirect_to tools_survey_offers_path
  end

  private

  def find_survey_offer
    @survey_offer = SurveyOffer.find(params[:id])
  end
end
