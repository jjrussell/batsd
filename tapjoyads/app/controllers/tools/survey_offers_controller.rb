class Tools::SurveyOffersController < WebsiteController
  layout 'tabbed'

  current_tab :tools

  filter_access_to :all

  before_filter :find_survey_offer, :only => [ :edit, :update, :destroy ]

  def index
    @survey_offers = SurveyOffer.visible
  end

  def new
    @survey_offer = SurveyOffer.new(:bid => 0)
    @survey_offer.build_blank_questions
  end

  def create
    sanitize_currency_params(params[:survey_offer], [ :bid ])
    questions_attrs = params[:survey_offer].delete(:survey_questions_attributes)
    options = { :survey_questions_attributes => questions_attrs }
    @survey_offer = SurveyOffer.new(params[:survey_offer])

    # accepts_attributes_for doesn't play nice with UuidPrimaryKey on creation
    if @survey_offer.save && @survey_offer.update_attributes(options)
      flash[:notice] = 'Survey offer created successfully'
      redirect_to tools_survey_offers_path
    else
      flash.now[:error] = 'Problems creating survey offer'
      @survey_offer.build_blank_questions
      render :action => :new
    end
  end

  def edit
    @survey_offer.build_blank_questions
  end

  def update
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

  private

  def find_survey_offer
    @survey_offer = SurveyOffer.find(params[:id])
  end
end
